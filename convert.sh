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

    # Fix footnote format - convert [^1]: to ¹ and [^1] to ¹
    sed -i 's/\[^1\]:/¹/g' "$file"
    sed -i 's/\[^1\]/¹/g' "$file"
    sed -i 's/\[^2\]:/²/g' "$file"
    sed -i 's/\[^2\]/²/g' "$file"
    sed -i 's/\[^3\]:/³/g' "$file"
    sed -i 's/\[^3\]/³/g' "$file"

    # Fix appendix references
    sed -i 's/\[Appendix \([A-Z0-9]\)\]([^)]*)/Appendix \1/g' "$file"
    sed -i 's/\[Appendix \([A-Z0-9]\)\]/Appendix \1/g' "$file"

    # Clean up broken table formatting and empty table rows
    sed -i 's/\\\$/$/g' "$file"
    sed -i 's/\\,/,/g' "$file"
    sed -i 's/<div class="center">//g' "$file"
    sed -i 's/<\/div>//g' "$file"
    sed -i '/^|[[:space:]]*|[[:space:]]*|[[:space:]]*|[[:space:]]*|$/d' "$file"
    sed -i '/^|[[:space:]]*-*[[:space:]]*|[[:space:]]*-*[[:space:]]*|[[:space:]]*-*[[:space:]]*|[[:space:]]*-*[[:space:]]*|$/d' "$file"

    # Fix dollar signs and currency formatting
    sed -i 's/\\\$/$$/g' "$file"
    sed -i 's/\\$/$/g' "$file"

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
    sed -i 's/\\multicolumn{[^}]*}{[^}]*}{[^}]*}//g' "$file"
    sed -i 's/\\textbf{//g' "$file"
    sed -i 's/}//g' "$file"

    # Remove empty lines at the beginning of the file
    sed -i '/./,$!d' "$file"
}

# Create output directory
mkdir -p output

# Create the complete Python fix script
cat > fix_conversion.py << 'PYTHON_SCRIPT_END'
import re
import sys

def fix_yaml_frontmatter(content):
    """Fix YAML frontmatter issues"""
    lines = content.split('\n')
    if not (lines[0].strip() == '---' and '---' in lines[1:]):
        return content

    # Find the frontmatter section
    end_index = -1
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == '---':
            end_index = i
            break

    if end_index == -1:
        return content

    # Fix frontmatter lines
    frontmatter_lines = lines[1:end_index]
    fixed_frontmatter = []

    for line in frontmatter_lines:
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()

            # Ensure proper quoting for string values
            if value and not value.startswith('"') and not value.isdigit() and value not in ['true', 'false']:
                if '"' in value:
                    value = value.replace('"', '\\"')
                value = f'"{value}"'

            fixed_frontmatter.append(f'{key}: {value}')
        else:
            fixed_frontmatter.append(line)

    # Reconstruct content
    return '\n'.join(['---'] + fixed_frontmatter + ['---'] + lines[end_index + 1:])

def fix_encoding_issues(content):
    """Fix character encoding problems"""
    # More aggressive character filtering - keep only safe ASCII
    safe_content = ""
    for char in content:
        if ord(char) <= 127:  # Basic ASCII
            safe_content += char
        elif char in '¹²³':  # Keep superscript numbers
            safe_content += char
        elif char in '—–':  # Keep em/en dashes
            safe_content += char
        else:
            # Replace problematic characters with space
            safe_content += ' '

    content = safe_content

    # General pattern fixes
    fixes = [
        # Fix word spacing issues
        (r'([a-z])([A-Z])', r'\1 \2'),  # Add space between lowercase and uppercase
        (r'(\d+)([a-zA-Z])', r'\1 \2'),  # Add space between numbers and letters
        (r'([a-zA-Z])(\d+)', r'\1 \2'),  # Add space between letters and numbers

        # Fix broken monetary amounts
        (r'(\d+),(\d{3})', r'\1,\2'),
        (r'\\?\$\s*(\d+)\.(\d+)\s*billion', r'$\1.\2 billion'),
        (r'\\?\$\s*(\d+)\s*billion', r'$\1 billion'),
        (r'\\?\$\s*(\d+),(\d{3})', r'$\1,\2'),

        # Fix periods and spacing
        (r'([a-z])\.\s*([a-z])', r'\1. \2'),  # Fix period spacing
        (r'([a-z])\s+\.\s*([A-Z])', r'\1. \2'),  # Fix misplaced periods

        # Clean up excessive spaces and dots
        (r'\.{2,}', '.'),
        (r'\s{3,}', ' '),
        (r'\n\s*\n\s*\n+', '\n\n'),

        # Fix percentage formatting
        (r'(\d+)\s*%', r'\1%'),

        # Fix common LaTeX artifacts
        (r'---', '—'),  # Convert triple dash to em dash
        (r'--', '–'),   # Convert double dash to en dash

        # Fix common word breaks
        (r'annuallynot', 'annually—not'),
        (r'one\.\s*time', 'one-time'),
        (r'million\.\s*dollar', 'million-dollar'),
        (r'Zero\.\s*knowledge', 'Zero-knowledge'),
        (r'doesnt', "doesn't"),
        (r'processesit', 'processes—it'),
        (r'rate\.\s*embedded', 'rate-embedded'),
    ]

    for pattern, replacement in fixes:
        content = re.sub(pattern, replacement, content, flags=re.IGNORECASE)

    return content

def fix_table_formatting(content):
    """Fix table formatting issues"""
    lines = content.split('\n')
    fixed_lines = []
    in_table = False
    table_rows = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped_line = line.strip()

        # Skip obviously broken table content that's mixed with text
        if ('|' in stripped_line and
            len(stripped_line) > 200 and
            ('The Elephant protocol' in stripped_line or
             'This transformation' in stripped_line)):
            # This is corrupted table content mixed with text - skip and try to extract text
            text_parts = re.split(r'\|[^|]*\|', stripped_line)
            for part in text_parts:
                clean_part = part.strip()
                if clean_part and len(clean_part) > 20:
                    fixed_lines.append(clean_part)
            i += 1
            continue

        # Check if this looks like a proper table row
        if '|' in stripped_line and stripped_line.count('|') >= 2:
            if not in_table:
                in_table = True
                table_rows = []

            # Clean the table row
            cleaned_row = re.sub(r'\s*\|\s*', ' | ', stripped_line.strip())

            # Remove any text that got mixed into table cells
            cells = cleaned_row.split('|')
            clean_cells = []
            for cell in cells:
                cell = cell.strip()
                # Skip cells that are obviously corrupted (too long or contain sentences)
                if len(cell) > 50 or (len(cell.split()) > 6 and any(word in cell.lower() for word in ['the', 'this', 'that', 'which', 'because'])):
                    continue
                clean_cells.append(cell)

            if len(clean_cells) >= 3:  # Need at least 3 meaningful cells
                cleaned_row = '| ' + ' | '.join(clean_cells) + ' |'
                table_rows.append(cleaned_row)
        else:
            # End of table
            if in_table and table_rows:
                # Process the table
                if len(table_rows) >= 2:  # Need at least header + one data row
                    # Add header row
                    fixed_lines.append(table_rows[0])

                    # Add alignment row
                    col_count = table_rows[0].count('|') - 1
                    if col_count > 0:
                        alignment = '|' + ' --- |' * col_count
                        fixed_lines.append(alignment)

                    # Add data rows
                    for row in table_rows[1:]:
                        fixed_lines.append(row)

                # Add spacing after table
                fixed_lines.append('')
                table_rows = []
                in_table = False

            # Add non-table line if it's not empty
            if stripped_line and not in_table:
                fixed_lines.append(line)
            elif not in_table and not stripped_line:  # Preserve empty lines outside tables
                fixed_lines.append('')

        i += 1

    # Handle table at end of content
    if in_table and table_rows:
        if len(table_rows) >= 2:
            fixed_lines.append(table_rows[0])
            col_count = table_rows[0].count('|') - 1
            if col_count > 0:
                alignment = '|' + ' --- |' * col_count
                fixed_lines.append(alignment)
            for row in table_rows[1:]:
                fixed_lines.append(row)

    return '\n'.join(fixed_lines)

def fix_footnotes(content):
    """Fix footnote formatting"""
    # Convert LaTeX footnotes to superscript numbers
    footnote_patterns = [
        (r'\\footnote\{([^}]+)\}', r'¹'),  # Convert \footnote{text} to ¹
        (r'\[(\d+)\]', r'¹'),  # Convert [1] to ¹
        (r'\[\^(\d+)\]', r'¹'),  # Convert [^1] to ¹
    ]

    for pattern, replacement in footnote_patterns:
        content = re.sub(pattern, replacement, content)

    return content

def fix_markdown_content(content, filename):
    """Comprehensive markdown fixing with YAML support"""
    # Fix YAML frontmatter FIRST (before any other processing)
    content = fix_yaml_frontmatter(content)

    # Fix encoding issues
    content = fix_encoding_issues(content)

    # Fix footnotes
    content = fix_footnotes(content)

    # Fix table formatting
    content = fix_table_formatting(content)

    # Fix line wrapping issues (preserve table lines and frontmatter)
    lines = content.split('\n')
    fixed_lines = []
    in_frontmatter = False
    i = 0

    while i < len(lines):
        line = lines[i]

        # Handle frontmatter
        if line.strip() == '---':
            in_frontmatter = not in_frontmatter
            fixed_lines.append(line)
            i += 1
            continue

        if in_frontmatter:
            fixed_lines.append(line)
            i += 1
            continue

        # Skip table lines and headers for line joining
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

    # Final cleanup
    content = re.sub(r' {2,}', ' ', content)
    content = re.sub(r'\n{3,}', '\n\n')

    # Remove any remaining LaTeX artifacts
    content = re.sub(r'\\[a-zA-Z]+\{[^}]*\}', '', content)
    content = re.sub(r'\\[a-zA-Z]+', '', content)

    return content

if __name__ == "__main__":
    filename = sys.argv[1]
    try:
        # Read with explicit UTF-8 encoding
        with open(filename, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()

        fixed_content = fix_markdown_content(content, filename)

        # Write with explicit UTF-8 encoding
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(fixed_content)

        print(f"✅ Fixed: {filename}")
    except Exception as e:
        print(f"❌ Error fixing {filename}: {e}")
PYTHON_SCRIPT_END

# Convert documents with frontmatter
echo "🔄 Converting LaTeX files to Markdown with frontmatter..."
today=$(date +%F)

find . -maxdepth 1 -name "*.tex" -not -name "Full Doc.tex" > tex_list.txt

while IFS= read -r tex_file; do
    [ ! -f "$tex_file" ] && echo "Skipping: $tex_file" && continue
    echo "Converting: $tex_file"
    base_name=$(basename "$tex_file" .tex)

    # Get chapter title
    chapter_title=$(grep '\\chapter{' "$tex_file" | head -1 | sed 's/.*\\chapter{//;s/}.*//' || echo "Chapter")
    chapter_title_clean=$(echo "$chapter_title" | tr -cd '[:alnum:] .:/-' | sed 's/["\\]/ /g')
    slug=$(echo "$chapter_title_clean" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Check if file has sections
    if grep -q '\\section{' "$tex_file"; then
        echo "File has sections - creating intro + section files"

        # Create intro file for chapters with sections
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
            echo "has_sections: true"
            echo "toc: true"
            echo "description: \"\""
            echo "draft: false"
            echo "---"
            echo ""
            echo "$intro_lines" | LANG=en_US.UTF-8 pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone
        } > "output/${base_name}.md"

        clean_markdown "output/${base_name}.md"
        python3 fix_conversion.py "output/${base_name}.md"
        echo "✅ Created intro: output/${base_name}.md"

        # Split sections for files that have them
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
                    cmd = "LANG=en_US.UTF-8 pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone " temp_file " >> " outname
                    system(cmd)
                    filecount++
                    print "✅ Created section: " outname
                }
                system("rm -f " temp_file)
            }
        ' "$tex_file"
    else
        echo "File has no sections - creating single file"

        # Create single file for chapters without sections (like Abstract)
        all_content=$(sed 's/\\chapter{.*}//' "$tex_file" | sed 's/^[[:space:]]*//')
        {
            echo "---"
            echo "title: \"$chapter_title_clean\""
            echo "slug: \"$slug\""
            echo "publishDate: \"$today\""
            echo "chapter: \"$chapter_title_clean\""
            echo "section: \"$chapter_title_clean\""
            echo "parentSlug: \"$slug\""
            echo "order: 0"
            echo "has_sections: false"
            echo "toc: true"
            echo "description: \"\""
            echo "draft: false"
            echo "---"
            echo ""
            echo "$all_content" | LANG=en_US.UTF-8 pandoc -f latex -t gfm --wrap=preserve --markdown-headings=atx --standalone
        } > "output/${base_name}.md"

        clean_markdown "output/${base_name}.md"
        python3 fix_conversion.py "output/${base_name}.md"
        echo "✅ Created: output/${base_name}.md"
    fi
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