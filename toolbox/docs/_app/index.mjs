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

const PORT = process.env.PORT || 3001;

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

const domain = os.hostname().toLowerCase();
const keyPath = relativePath(`../../misc/certificates/${domain}.key`);
const certPath = relativePath(`../../misc/certificates/${domain}.crt`);

if (existsSync(keyPath) && existsSync(certPath)) {
  const privateKey = await readFile(keyPath, "utf8");
  const certificate = await readFile(certPath, "utf8");

  const httpsServer = createHttpsServer(
    { key: privateKey, cert: certificate },
    app
  );

  httpsServer.listen(PORT, () => {
    console.log(`Toolbox Docs available at https://${domain}:${PORT}`);
    opener(`https://${domain}:${PORT}`);
  });
} else {
  const httpServer = createHttpServer(app);
  httpServer.listen(PORT, async () => {
    console.log(`Toolbox Docs available at http://localhost:${PORT}`);
    opener(`http://localhost:${PORT}`);
  });
}
