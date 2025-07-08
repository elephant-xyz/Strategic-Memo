#!/bin/bash

echo "📚 Converting LaTeX files to Markdown..."

# Function to clean up LaTeX artifacts
clean_markdown() {
    local file="$1"

    # Remove escaped backslashes from headers
    sed -i 's/\\#/#/g' "$file"
    sed -i 's/\\\*/*/g' "$file"
    sed -i 's/\/_/_/g' "$file"

    # Remove any lines that start with # (all headers)
    sed -i '/^#.*$/d' "$file"

    # Convert footnotes to proper numbered format
    sed -i 's/\\footnote{[^}]*}/¹/g' "$file"
    sed -i 's/^: /¹/g' "$file"

    # Fix appendix references
    sed -i 's/\[Appendix \([A-Z0-9]\)\]([^)]*)/Appendix \1/g' "$file"
    sed -i 's/\[Appendix \([A-Z0-9]\)\]/Appendix \1/g' "$file"

    # Clean up broken table formatting
    sed -i 's/\\\$/$/g' "$file"
    sed -i 's/\\,/,/g' "$file"
    sed -i 's/<div class="center">//g' "$file"
    sed -i 's/<\/div>//g' "$file"
    sed -i '/^|[[:space:]]*|[[:space:]]*|[[:space:]]*|[[:space:]]*|$/d' "$file"

    # Fix double spaces and improve paragraph spacing
    sed -i 's/  \+/ /g' "$file"
    sed -i 's/\n\n\n\+/\n\n/g' "$file"

    # Remove leading/trailing whitespace
    sed -i 's/^[[:space:]]*//' "$file"
    sed -i 's/[[:space:]]*$//' "$file"

    # Clean up any remaining LaTeX commands
    sed -i 's/\\begin{[^}]*}//g' "$file"
    sed -i 's/\\end{[^}]*}//g' "$file"
    sed -i 's/\\center//g' "$file"
    sed -i 's/\\centering//g' "$file"
    sed -i 's/\\hline//g' "$file"
}

# Create comprehensive fix script
create_fix_script() {
    cat > fix_conversion.py << 'EOF'
import re
import sys

def fix_universal_tables(content):
    """Universal table fixing that works for any table structure"""

    # Step 1: Remove broken table alignment rows (like |---|---|---|---|)
    content = re.sub(r'^\|[\-:]+\|[\-:]+\|[\-:]+\|[\-:]*\|?

# Create output directory
mkdir -p output

# Create the Python fix script
create_fix_script

# Convert full documents
echo "🔄 Converting full documents..."
find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" | while read -r tex_file; do
    base_name=$(basename "$tex_file" .tex)
    echo "Converting: $tex_file"

    # Convert with better options
    pandoc -f latex -t gfm \
           --wrap=preserve \
           --markdown-headings=atx \
           --standalone \
           --preserve-tabs \
           "$tex_file" -o "output/${base_name}.md"

    if [ $? -eq 0 ]; then
        # Clean up the generated markdown
        clean_markdown "output/${base_name}.md"

        # Add footnote marker for Abstract
        if [ "$base_name" = "1_Abstract" ]; then
            sed -i 's/decades of excess interest\./decades of excess interest.¹/g' "output/${base_name}.md"
        fi

        # Apply comprehensive fixes
        python3 fix_conversion.py "output/${base_name}.md"

        echo "✅ Created: output/${base_name}.md"
    else
        echo "❌ Failed: $tex_file"
    fi
done

# Create intro and section files
echo "🔄 Creating intro and section files..."
today=$(date +%F)

find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" > tex_list.txt

while IFS= read -r tex_file; do
    [ ! -f "$tex_file" ] && echo "Skipping: $tex_file" && continue
    echo "Processing sections: $tex_file"
    base_name=$(basename "$tex_file" .tex)

    # Get chapter title
    chapter_title=$(grep '\\chapter{' "$tex_file" | head -1 | sed 's/.*\\chapter{//;s/}.*//' || echo "Chapter")
    chapter_title_clean=$(echo "$chapter_title" | tr -cd '[:alnum:] .:/-' | sed 's/["\\]/ /g')
    slug=$(echo "$chapter_title_clean" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Create intro file
    intro_lines=$(awk '/\\section\{/{exit} {print}' "$tex_file" | sed 's/\\chapter{.*}//' | sed 's/^[[:space:]]*//')
    {
        echo "---"
        echo "title: \"$chapter_title_clean\""
        echo "slug: \"$slug\""
        echo "publishDate: \"$today\""
        echo "chapter: \"$chapter_title_clean\""
        echo "section: \"$chapter_title_clean\""
        echo "parentSlug: \"$slug\""
        echo "order: 0"
        echo "toc: true"
        echo "description: \"\""
        echo "draft: false"
        echo "---"
        echo ""
        echo "$intro_lines" | pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone
    } > "output/${base_name}_intro.md"

    clean_markdown "output/${base_name}_intro.md"
    python3 fix_conversion.py "output/${base_name}_intro.md"
    echo "📄 Created: output/${base_name}_intro.md"

    # Split sections (keeping the awk logic as it works well)
    awk -v base="$base_name" -v parent="$slug" -v chapter="$chapter_title_clean" -v today="$today" '
        BEGIN { filecount = 1; in_section = 0; section_title = ""; section_content = "" }
        /^\\section\{/ {
            if (in_section && section_title != "") { save_section() }
            in_section = 1
            section_title = substr($0, 10)
            section_title = substr(section_title, 1, index(section_title, "}") - 1)
            section_content = ""
            next
        }
        in_section {
            if (section_content == "") {
                section_content = $0
            } else {
                section_content = section_content "\n" $0
            }
        }
        END { if (in_section && section_title != "") { save_section() } }
        function save_section() {
            gsub(/[[:space:]]+$/, "", section_title)
            gsub(/\\\\/, "", section_title)
            gsub(/"/, "", section_title)
            gsub(/[^[:alnum:] .:-]/, "", section_title)
            slugified = tolower(section_title)
            gsub(/[^a-z0-9]+/, "-", slugified)
            gsub(/^-|-$/, "", slugified)
            outname = "output/" base "_section_" filecount ".md"
            temp_file = "temp_section_" filecount ".tex"
            print section_content > temp_file
            if (system("test -s " temp_file) == 0) {
                print "---" > outname
                print "title: \"" section_title "\"" >> outname
                print "slug: \"" slugified "\"" >> outname
                print "publishDate: \"" today "\"" >> outname
                print "chapter: \"" chapter "\"" >> outname
                print "section: \"" section_title "\"" >> outname
                print "parentSlug: \"" parent "\"" >> outname
                print "order: " filecount >> outname
                print "toc: true" >> outname
                print "description: \"\"" >> outname
                print "draft: false" >> outname
                print "---" >> outname
                print "" >> outname
                cmd = "pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone " temp_file " >> " outname
                system(cmd)
                filecount++
            }
            system("rm -f " temp_file)
        }
    ' "$tex_file"
done < tex_list.txt

# Final cleanup
echo "🧹 Final cleanup..."
for file in output/*.md; do
    if [ -f "$file" ]; then
        python3 fix_conversion.py "$file"
    fi
done

# Cleanup temporary files
rm -f tex_list.txt fix_conversion.py

echo "🎉 Conversion complete! Check the output/ directory.", '', content, flags=re.MULTILINE)

    # Step 2: Find all table-like structures and fix them
    lines = content.split('\n')
    fixed_lines = []
    in_table = False
    table_buffer = []

    for i, line in enumerate(lines):
        # Detect table start (line with multiple |)
        if '|' in line and line.count('|') >= 2:
            if not in_table:
                in_table = True
                table_buffer = []
            table_buffer.append(line.strip())
        else:
            # End of table or not a table line
            if in_table and table_buffer:
                # Process the accumulated table
                fixed_table = fix_single_table(table_buffer)
                fixed_lines.extend(fixed_table)
                table_buffer = []
                in_table = False

            if line.strip():  # Don't lose non-table content
                fixed_lines.append(line)

    # Handle table at end of file
    if in_table and table_buffer:
        fixed_table = fix_single_table(table_buffer)
        fixed_lines.extend(fixed_table)

    return '\n'.join(fixed_lines)

def fix_single_table(table_lines):
    """Fix a single table's structure"""
    if not table_lines:
        return []

    # Clean up each table line
    cleaned_lines = []
    for line in table_lines:
        # Remove excessive whitespace around pipes
        line = re.sub(r'\s*\|\s*', ' | ', line)
        # Ensure line starts and ends properly
        if not line.startswith('|'):
            line = '| ' + line
        if not line.endswith('|'):
            line = line + ' |'
        # Clean up double pipes
        line = re.sub(r'\|\s*\|', '| |', line)
        cleaned_lines.append(line.strip())

    # If we have table content, add proper alignment row
    if len(cleaned_lines) >= 1:
        # Count columns from first row
        first_row = cleaned_lines[0]
        col_count = first_row.count('|') - 1  # Subtract 1 for edge pipes

        # Create alignment row
        alignment_row = '|' + '---|' * col_count

        # Insert alignment row after header (if it doesn't exist)
        if len(cleaned_lines) == 1 or not re.match(r'^\|[\-:|\s]+\|

# Create output directory
mkdir -p output

# Create the Python fix script
create_fix_script

# Convert full documents
echo "🔄 Converting full documents..."
find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" | while read -r tex_file; do
    base_name=$(basename "$tex_file" .tex)
    echo "Converting: $tex_file"

    # Convert with better options
    pandoc -f latex -t gfm \
           --wrap=preserve \
           --markdown-headings=atx \
           --standalone \
           --preserve-tabs \
           "$tex_file" -o "output/${base_name}.md"

    if [ $? -eq 0 ]; then
        # Clean up the generated markdown
        clean_markdown "output/${base_name}.md"

        # Add footnote marker for Abstract
        if [ "$base_name" = "1_Abstract" ]; then
            sed -i 's/decades of excess interest\./decades of excess interest.¹/g' "output/${base_name}.md"
        fi

        # Apply comprehensive fixes
        python3 fix_conversion.py "output/${base_name}.md"

        echo "✅ Created: output/${base_name}.md"
    else
        echo "❌ Failed: $tex_file"
    fi
done

# Create intro and section files
echo "🔄 Creating intro and section files..."
today=$(date +%F)

find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" > tex_list.txt

while IFS= read -r tex_file; do
    [ ! -f "$tex_file" ] && echo "Skipping: $tex_file" && continue
    echo "Processing sections: $tex_file"
    base_name=$(basename "$tex_file" .tex)

    # Get chapter title
    chapter_title=$(grep '\\chapter{' "$tex_file" | head -1 | sed 's/.*\\chapter{//;s/}.*//' || echo "Chapter")
    chapter_title_clean=$(echo "$chapter_title" | tr -cd '[:alnum:] .:/-' | sed 's/["\\]/ /g')
    slug=$(echo "$chapter_title_clean" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Create intro file
    intro_lines=$(awk '/\\section\{/{exit} {print}' "$tex_file" | sed 's/\\chapter{.*}//' | sed 's/^[[:space:]]*//')
    {
        echo "---"
        echo "title: \"$chapter_title_clean\""
        echo "slug: \"$slug\""
        echo "publishDate: \"$today\""
        echo "chapter: \"$chapter_title_clean\""
        echo "section: \"$chapter_title_clean\""
        echo "parentSlug: \"$slug\""
        echo "order: 0"
        echo "toc: true"
        echo "description: \"\""
        echo "draft: false"
        echo "---"
        echo ""
        echo "$intro_lines" | pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone
    } > "output/${base_name}_intro.md"

    clean_markdown "output/${base_name}_intro.md"
    python3 fix_conversion.py "output/${base_name}_intro.md"
    echo "📄 Created: output/${base_name}_intro.md"

    # Split sections (keeping the awk logic as it works well)
    awk -v base="$base_name" -v parent="$slug" -v chapter="$chapter_title_clean" -v today="$today" '
        BEGIN { filecount = 1; in_section = 0; section_title = ""; section_content = "" }
        /^\\section\{/ {
            if (in_section && section_title != "") { save_section() }
            in_section = 1
            section_title = substr($0, 10)
            section_title = substr(section_title, 1, index(section_title, "}") - 1)
            section_content = ""
            next
        }
        in_section {
            if (section_content == "") {
                section_content = $0
            } else {
                section_content = section_content "\n" $0
            }
        }
        END { if (in_section && section_title != "") { save_section() } }
        function save_section() {
            gsub(/[[:space:]]+$/, "", section_title)
            gsub(/\\\\/, "", section_title)
            gsub(/"/, "", section_title)
            gsub(/[^[:alnum:] .:-]/, "", section_title)
            slugified = tolower(section_title)
            gsub(/[^a-z0-9]+/, "-", slugified)
            gsub(/^-|-$/, "", slugified)
            outname = "output/" base "_section_" filecount ".md"
            temp_file = "temp_section_" filecount ".tex"
            print section_content > temp_file
            if (system("test -s " temp_file) == 0) {
                print "---" > outname
                print "title: \"" section_title "\"" >> outname
                print "slug: \"" slugified "\"" >> outname
                print "publishDate: \"" today "\"" >> outname
                print "chapter: \"" chapter "\"" >> outname
                print "section: \"" section_title "\"" >> outname
                print "parentSlug: \"" parent "\"" >> outname
                print "order: " filecount >> outname
                print "toc: true" >> outname
                print "description: \"\"" >> outname
                print "draft: false" >> outname
                print "---" >> outname
                print "" >> outname
                cmd = "pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone " temp_file " >> " outname
                system(cmd)
                filecount++
            }
            system("rm -f " temp_file)
        }
    ' "$tex_file"
done < tex_list.txt

# Final cleanup
echo "🧹 Final cleanup..."
for file in output/*.md; do
    if [ -f "$file" ]; then
        python3 fix_conversion.py "$file"
    fi
done

# Cleanup temporary files
rm -f tex_list.txt fix_conversion.py

echo "🎉 Conversion complete! Check the output/ directory.", cleaned_lines[1]):
            cleaned_lines.insert(1, alignment_row)
        else:
            # Replace existing malformed alignment row
            cleaned_lines[1] = alignment_row

    return cleaned_lines

def fix_markdown_content(content, filename):
    """Comprehensive markdown fixing"""

    # Fix footnote issues first
    content = re.sub(r'¹\[^1\]', '¹', content)
    content = re.sub(r'excess interest\.\s*\[^1\]', 'excess interest.¹', content)
    content = re.sub(r'excess interest\.¹\[^1\]', 'excess interest.¹', content)

    # UNIVERSAL TABLE FIXING - works for any table
    content = fix_universal_tables(content)

    # Fix tables that appear mid-sentence (like in Abstract)
    # Look for sentences ending with period followed immediately by table
    content = re.sub(r'(\w\.)\s*(\|[^|]*\|)', r'\1\n\n\2', content)

    # Fix line wrapping issues (but preserve table lines)
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Skip table lines and headers
        if (i + 1 < len(lines) and
            line and not line.startswith('|') and not line.startswith('#') and
            not line.startswith('---') and
            lines[i + 1] and lines[i + 1][0].islower() and
            not lines[i + 1].startswith('|')):
            # Join broken lines
            line = line + ' ' + lines[i + 1].strip()
            i += 2
        else:
            i += 1
        fixed_lines.append(line)

    content = '\n'.join(fixed_lines)

    # Clean up excessive whitespace
    content = re.sub(r' {2,}', ' ', content)
    content = re.sub(r'\n{3,}', '\n\n', content)

    # Ensure footnote is at the end
    footnote_match = re.search(r'\[^1\]:\s*(.+)', content)
    if footnote_match:
        footnote_content = footnote_match.group(0)
        content = re.sub(r'\[^1\]:\s*(.+)', '', content)
        content = content.rstrip() + '\n\n' + footnote_content

    return content

if __name__ == "__main__":
    filename = sys.argv[1]
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = f.read()

        fixed_content = fix_markdown_content(content, filename)

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(fixed_content)

        print(f"✅ Fixed: {filename}")
    except Exception as e:
        print(f"❌ Error fixing {filename}: {e}")
EOF
}

# Create output directory
mkdir -p output

# Create the Python fix script
create_fix_script

# Convert full documents
echo "🔄 Converting full documents..."
find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" | while read -r tex_file; do
    base_name=$(basename "$tex_file" .tex)
    echo "Converting: $tex_file"

    # Convert with better options
    pandoc -f latex -t gfm \
           --wrap=preserve \
           --markdown-headings=atx \
           --standalone \
           --preserve-tabs \
           "$tex_file" -o "output/${base_name}.md"

    if [ $? -eq 0 ]; then
        # Clean up the generated markdown
        clean_markdown "output/${base_name}.md"

        # Add footnote marker for Abstract
        if [ "$base_name" = "1_Abstract" ]; then
            sed -i 's/decades of excess interest\./decades of excess interest.¹/g' "output/${base_name}.md"
        fi

        # Apply comprehensive fixes
        python3 fix_conversion.py "output/${base_name}.md"

        echo "✅ Created: output/${base_name}.md"
    else
        echo "❌ Failed: $tex_file"
    fi
done

# Create intro and section files
echo "🔄 Creating intro and section files..."
today=$(date +%F)

find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" > tex_list.txt

while IFS= read -r tex_file; do
    [ ! -f "$tex_file" ] && echo "Skipping: $tex_file" && continue
    echo "Processing sections: $tex_file"
    base_name=$(basename "$tex_file" .tex)

    # Get chapter title
    chapter_title=$(grep '\\chapter{' "$tex_file" | head -1 | sed 's/.*\\chapter{//;s/}.*//' || echo "Chapter")
    chapter_title_clean=$(echo "$chapter_title" | tr -cd '[:alnum:] .:/-' | sed 's/["\\]/ /g')
    slug=$(echo "$chapter_title_clean" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Create intro file
    intro_lines=$(awk '/\\section\{/{exit} {print}' "$tex_file" | sed 's/\\chapter{.*}//' | sed 's/^[[:space:]]*//')
    {
        echo "---"
        echo "title: \"$chapter_title_clean\""
        echo "slug: \"$slug\""
        echo "publishDate: \"$today\""
        echo "chapter: \"$chapter_title_clean\""
        echo "section: \"$chapter_title_clean\""
        echo "parentSlug: \"$slug\""
        echo "order: 0"
        echo "toc: true"
        echo "description: \"\""
        echo "draft: false"
        echo "---"
        echo ""
        echo "$intro_lines" | pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone
    } > "output/${base_name}_intro.md"

    clean_markdown "output/${base_name}_intro.md"
    python3 fix_conversion.py "output/${base_name}_intro.md"
    echo "📄 Created: output/${base_name}_intro.md"

    # Split sections (keeping the awk logic as it works well)
    awk -v base="$base_name" -v parent="$slug" -v chapter="$chapter_title_clean" -v today="$today" '
        BEGIN { filecount = 1; in_section = 0; section_title = ""; section_content = "" }
        /^\\section\{/ {
            if (in_section && section_title != "") { save_section() }
            in_section = 1
            section_title = substr($0, 10)
            section_title = substr(section_title, 1, index(section_title, "}") - 1)
            section_content = ""
            next
        }
        in_section {
            if (section_content == "") {
                section_content = $0
            } else {
                section_content = section_content "\n" $0
            }
        }
        END { if (in_section && section_title != "") { save_section() } }
        function save_section() {
            gsub(/[[:space:]]+$/, "", section_title)
            gsub(/\\\\/, "", section_title)
            gsub(/"/, "", section_title)
            gsub(/[^[:alnum:] .:-]/, "", section_title)
            slugified = tolower(section_title)
            gsub(/[^a-z0-9]+/, "-", slugified)
            gsub(/^-|-$/, "", slugified)
            outname = "output/" base "_section_" filecount ".md"
            temp_file = "temp_section_" filecount ".tex"
            print section_content > temp_file
            if (system("test -s " temp_file) == 0) {
                print "---" > outname
                print "title: \"" section_title "\"" >> outname
                print "slug: \"" slugified "\"" >> outname
                print "publishDate: \"" today "\"" >> outname
                print "chapter: \"" chapter "\"" >> outname
                print "section: \"" section_title "\"" >> outname
                print "parentSlug: \"" parent "\"" >> outname
                print "order: " filecount >> outname
                print "toc: true" >> outname
                print "description: \"\"" >> outname
                print "draft: false" >> outname
                print "---" >> outname
                print "" >> outname
                cmd = "pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone " temp_file " >> " outname
                system(cmd)
                filecount++
            }
            system("rm -f " temp_file)
        }
    ' "$tex_file"
done < tex_list.txt

# Final cleanup
echo "🧹 Final cleanup..."
for file in output/*.md; do
    if [ -f "$file" ]; then
        python3 fix_conversion.py "$file"
    fi
done

# Cleanup temporary files
rm -f tex_list.txt fix_conversion.py

echo "🎉 Conversion complete! Check the output/ directory."