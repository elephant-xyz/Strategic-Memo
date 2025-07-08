#!/bin/bash

echo "📚 Converting LaTeX files to Markdown..."

# Function to clean up LaTeX artifacts
clean_markdown() {
    local file="$1"
    # Remove escaped backslashes from headers
    sed -i 's/\\#/#/g' "$file"
    sed -i 's/\\\*/*/g' "$file"
    sed -i 's/\\_/_/g' "$file"
    # Remove any lines that start with # (all headers)
    sed -i '/^#.*$/d' "$file"
    # Remove footnote references and content
    sed -i 's/\[^[0-9]*\]//g' "$file"
    sed -i '/^\[^[0-9]*\]:/d' "$file"
    # Fix double spaces and improve paragraph spacing
    sed -i 's/  \+/ /g' "$file"
    sed -i 's/\n\n\n\+/\n\n/g' "$file"
    # Remove leading/trailing whitespace
    sed -i 's/^[[:space:]]*//' "$file"
    sed -i 's/[[:space:]]*$//' "$file"
}

# Create output directory
mkdir -p output

# Find all .tex files (excluding Full Doc.tex and title.tex)
find . -name "*.tex" -not -name "Full Doc.tex" -not -name "title.tex" | while read -r tex_file; do
    echo "🔄 Processing: $tex_file"
    
    # Get base name without .tex extension
    base_name=$(basename "$tex_file" .tex)
    
    # Convert to markdown using improved pandoc options
    pandoc -f latex -t markdown --wrap=auto --columns=120 --markdown-headings=atx --standalone "$tex_file" -o "output/${base_name}.md"
    
    if [ $? -eq 0 ]; then
        # Clean up the generated markdown
        clean_markdown "output/${base_name}.md"
        echo "✅ Created: output/${base_name}.md"
    else
        echo "❌ Failed to convert: $tex_file"
    fi
done

echo "🎉 Conversion complete! Check the output/ directory for Markdown files." 