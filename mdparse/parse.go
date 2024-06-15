package main

import (
	"bytes"
	"fmt"
	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/text"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

func parseMarkdown(file string) error {
	log.Printf("Reading markdown file: %s", file)
	content, err := ioutil.ReadFile(file)
	if err != nil {
		log.Printf("Error reading file: %s", err)
		return fmt.Errorf("failed to read file: %w", err)
	}

	md := goldmark.New()
	doc := md.Parser().Parse(text.NewReader(content))

	err = ast.Walk(doc, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}

		if n.Kind() == ast.KindFencedCodeBlock {
			log.Println("Fenced code block found -- ", n.Kind())
			codeBlock := n.(*ast.FencedCodeBlock)
			language := string(codeBlock.Language(content))
			filename, ok := extractFilename(language)
			if ok {
				log.Printf("Extracted filename: %s", filename)
				codeContent := extractCodeBlockContent(codeBlock, content)
				err := writeFile(filename, codeContent)
				if err != nil {
					log.Printf("Error writing to file: %s", err)
					return ast.WalkStop, err
				}
			}
		}

		return ast.WalkContinue, nil
	})

	if err != nil {
		log.Printf("Error walking through AST: %s", err)
		return fmt.Errorf("failed to walk through AST: %w", err)
	}

	log.Println("Markdown parsing completed successfully")
	return nil
}

func extractFilename(language string) (string, bool) {
	if strings.HasPrefix(language, "**") && strings.HasSuffix(language, "**:") {
		filename := strings.TrimPrefix(language, "**")
		filename = strings.TrimSuffix(filename, "**:")
		log.Printf("Filename extracted: %s", filename)
		return filename, true
	}
	log.Println("No filename found in language specification")
	return "", false
}

func extractCodeBlockContent(codeBlock *ast.FencedCodeBlock, source []byte) string {
	var buf bytes.Buffer
	for i := 0; i < codeBlock.Lines().Len(); i++ {
		line := codeBlock.Lines().At(i)
		buf.Write(line.Value(source))
	}
	return buf.String()
}

func writeFile(filename, content string) error {
	log.Printf("Writing to file: %s", filename)
	if err := os.MkdirAll(getDir(filename), os.ModePerm); err != nil {
		log.Printf("Error creating directories: %s", err)
		return err
	}
	if err := ioutil.WriteFile(filename, []byte(content), 0644); err != nil {
		log.Printf("Error writing file: %s", err)
		return err
	}
	log.Printf("File written successfully: %s", filename)
	return nil
}

func getDir(filename string) string {
	return filename[:strings.LastIndex(filename, "/")]
}