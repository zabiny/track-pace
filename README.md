# Tempo na dráze

Static page for training on a 400 m track: https://tempo.zabiny.club

Each runner enters their 3000 m (or 1500 m) time and a per-km offset (+ slower / − faster); the page shows target 1 km, 400 m, 200 m and 100 m times. Czech by default, English via the CZ | EN switch. The runner list is stored only in the viewer's browser (localStorage); nothing is sent to a server.

- `index.html` — the whole app, no backend
- `logo.svg`, `frog.svg` — club logo and favicon
- `Dockerfile` — nginx image serving the files

Deploying: see [DEPLOY.md](DEPLOY.md).
