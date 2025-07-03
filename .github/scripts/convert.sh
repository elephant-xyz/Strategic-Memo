#!/bin/bash

echo "📚 Converting LaTeX files to Markdown..."

# Create output directory
mkdir -p output

# Find all .tex files (excluding Full Doc.tex and title.tex)
find . -name "*.tex" -not -name "Full Doc.tex" -not -name "title.tex" | while read -r tex_file; do
    echo "🔄 Processing: $tex_file"
    
    # Get base name without .tex extension
    base_name=$(basename "$tex_file" .tex)
    
    # Convert to markdown using pandoc
    pandoc -f latex -t markdown_strict "$tex_file" -o "output/${base_name}.md"
    
    if [ $? -eq 0 ]; then
        echo "✅ Created: output/${base_name}.md"
    else
        echo "❌ Failed to convert: $tex_file"
    fi
done

echo "🎉 Conversion complete! Check the output/ directory for Markdown files." 