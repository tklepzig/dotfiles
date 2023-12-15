#!/usr/bin/env node

const path = require("path");
const { readFile } = require("fs/promises");
const { existsSync } = require("fs");
const express = require("express");

const app = express();
app.set("views", path.resolve(__dirname));
app.set("view engine", "ejs");

const md = require("markdown-it")({
  html: true,
  linkify: true,
  typographer: true,
}).use(require("markdown-it-named-headings"));

const PORT = process.env.PORT || 3001;
app.get("/favicon.ico", (_, response) => {
  //TODO
  response.sendStatus(200);
});
app.get("/sw.js", (_, response) => {
  response.sendFile(`${__dirname}/sw.js`);
});

app.get("/*.css", (request, response) => {
  response.sendFile(`${__dirname}/${request.path}`);
});

app.get("/:name?", async ({ params }, response) => {
  const file = `${__dirname}/../${params.name ?? "index"}.md`;
  if (!existsSync(file)) return response.sendStatus(404);

  const content = await readFile(file, "utf-8");

  response.render("md", {
    main: md.render(content),
  });
});

app.listen(PORT, () => {
  console.log(`Facts Events service listening at http://localhost:${PORT}`);
});
