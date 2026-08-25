import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const STORE_PATH = path.join(__dirname, "..", "giveaways.json");

let cache = null;

function load() {
  if (cache) {
    return cache;
  }

  try {
    cache = JSON.parse(fs.readFileSync(STORE_PATH, "utf8"));
  } catch {
    cache = { giveaways: [] };
  }

  if (!Array.isArray(cache.giveaways)) {
    cache.giveaways = [];
  }

  return cache;
}

function save() {
  fs.writeFileSync(STORE_PATH, JSON.stringify(cache, null, 2));
}

export function getAll() {
  return load().giveaways;
}

export function getGiveaway(id) {
  return getAll().find((g) => g.id === id) ?? null;
}

export function saveGiveaway(giveaway) {
  const all = load().giveaways;
  const index = all.findIndex((x) => x.id === giveaway.id);

  if (index >= 0) {
    all[index] = giveaway;
  } else {
    all.push(giveaway);
  }

  save();
}

export function removeGiveaway(id) {
  const all = load().giveaways;
  cache.giveaways = all.filter((x) => x.id !== id);
  save();
}

export function listActive() {
  return getAll().filter((g) => g.status === "active");
}
