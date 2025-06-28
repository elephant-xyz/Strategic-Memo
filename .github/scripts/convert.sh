#!/bin/bash
set -e

INPUT_DIR="."
OUTPUT_DIR="./output"

mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"/*.md

get_latest_versions() {
  find "$INPUT_DIR" -maxdepth 1 -name "*.tex" ! -name "Full Doc.tex" | while read file; do
    base=$(basename "$file" .tex)
    base_clean=$(echo "$base" | sed -E 's/_v[0-9]+$//' | sed -E 's/ +/_/g')
    version=$(echo "$base" | grep -oE '_v[0-9]+' | sed 's/_v//')
    echo "$base_clean|$version|$file"
  done | sort -t '|' -k1,1 -k2nr | awk -F '|' '!seen[$1]++ {print $3}'
}

echo "📚 Converting LaTeX chapters and sections to Markdown..."

for file in $(get_latest_versions); do
  base=$(basename "$file" .tex)
  base_clean=$(echo "$base" | sed -E 's/_v[0-9]+$//' | sed -E 's/^[0-9]+_//' | sed -E 's/_/ /g')
  chapter_slug=$(echo "$base_clean" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr 'A-Z' 'a-z')
  chapter_name="$base_clean"

  date="$(date -I)"

  # Extract chapter intro (everything before \section{)
  awk '/\\section\{/{exit} {print}' "$file" > /tmp/temp_intro.tex

  if [ -s /tmp/temp_intro.tex ]; then
    intro_slug="${chapter_slug}-intro"
    output_intro="$OUTPUT_DIR/$intro_slug.md"

    {
      echo "---"
      echo "title: \"Intro\""
      echo "slug: \"$intro_slug\""
      echo "publishDate: \"$date\""
      echo "chapter: \"$chapter_name\""
      echo "section: \"Intro\""
      echo "toc: true"
      echo "---"
      pandoc /tmp/temp_intro.tex -f latex -t markdown
    } > "$output_intro"

    echo "🟣 Created intro: $output_intro"
  fi

  # Parse sections
  awk -v chapter="$chapter_name" -v slug_prefix="$chapter_slug" -v outdir="$OUTPUT_DIR" -v date="$date" '
    BEGIN { RS="\\section{"; ORS="" }
    NR==1 { next }
    {
      split($0, parts, "}")
      section_title = parts[1]
      section_body = substr($0, length(section_title) + 2)

      section_slug = tolower(slug_prefix "-" gensub(/[^a-zA-Z0-9]+/, "-", "g", section_title))
      out_file = outdir "/" section_slug ".md"

      print "---\n" > out_file
      print "title: \"" section_title "\"" >> out_file
      print "slug: \"" section_slug "\"" >> out_file
      print "publishDate: \"" date "\"" >> out_file
      print "chapter: \"" chapter "\"" >> out_file
      print "section: \"" section_title "\"" >> out_file
      print "toc: true\n---\n" >> out_file

      # Use Pandoc for LaTeX → Markdown
      temp_tex = "/tmp/temp_section.tex"
      print "\\section{" section_title "}" section_body > temp_tex
      cmd = "pandoc " temp_tex " -f latex -t markdown"
      while ((cmd | getline line) > 0) print line >> out_file
      close(cmd)
      close(out_file)
      print "✅ Created " out_file
    }
  ' "$file"
done

echo "🎉 All Markdown files saved to $OUTPUT_DIR"
