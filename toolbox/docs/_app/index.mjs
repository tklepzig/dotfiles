#!/usr/bin/env node

import { readFile } from "fs/promises";
import { existsSync } from "fs";
import markdownIt from "markdown-it";
import namedHeadings from "markdown-it-named-headings";
import express from "express";
import { fileURLToPath } from "url";
import opener from "opener";

const relativePath = (file) => fileURLToPath(new URL(file, import.meta.url));

const app = express();
app.set("views", relativePath("."));
app.set("view engine", "ejs");

const md = markdownIt({ html: true, linkify: true, typographer: true }).use(
  namedHeadings
);

const PORT = process.env.PORT || 3001;
app.get("/favicon.ico", (_, response) => {
  //TODO
  response.sendStatus(200);
});
app.get("/sw.js", (_, response) => {
  response.sendFile(relativePath("sw.js"));
});

app.get("/*.css", (request, response) => {
  response.sendFile(relativePath(request.path.replace(/\//g, "")));
});

app.get("/:name*?", async ({ params }, response) => {
  const file = relativePath(
    params.name ? `../${params.name}${params[0]}.md` : "../index.md"
  );
  if (!existsSync(file)) return response.sendStatus(404);

  const content = await readFile(file, "utf-8");

  response.render("page", {
    main: md.render(content),
  });
});

app.listen(PORT, async () => {
  console.log(`Toolbox Docs available at http://localhost:${PORT}`);
  opener(`http://localhost:${PORT}`);
});
