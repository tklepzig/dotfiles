#!/usr/bin/env node

import { readFile } from "fs/promises";
import { existsSync } from "fs";
import markdownIt from "markdown-it";
import namedHeadings from "markdown-it-named-headings";
import express from "express";
import { createServer as createHttpServer } from "http";
import { createServer as createHttpsServer } from "https";
import { fileURLToPath } from "url";
import opener from "opener";
import os from "os";

const relativePath = (file) => fileURLToPath(new URL(file, import.meta.url));

const app = express();
app.set("views", relativePath("."));
app.set("view engine", "ejs");

const md = markdownIt({ html: true, linkify: true, typographer: true }).use(
  namedHeadings
);

const port = process.env.PORT || 3001;
const sslPort = process.env.SSL_PORT || 3002;

app.use(express.static(relativePath("public")));
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

createHttpServer(app).listen(port, async () => {
  console.log(`Toolbox Docs available at http://localhost:${port}`);
  opener(`http://localhost:${port}`);
});

const domain = os.hostname().toLowerCase();
const keyPath = relativePath(`../../misc/certificates/${domain}.key`);
const certPath = relativePath(`../../misc/certificates/${domain}.crt`);

if (existsSync(keyPath) && existsSync(certPath)) {
  const privateKey = await readFile(keyPath, "utf8");
  const certificate = await readFile(certPath, "utf8");

  createHttpsServer({ key: privateKey, cert: certificate }, app).listen(
    sslPort,
    () => {
      console.log(`Toolbox Docs PWA available at https://${domain}:${sslPort}`);
      opener(`https://${domain}:${sslPort}`);
    }
  );
}
