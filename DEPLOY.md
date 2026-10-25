# Deploying tempo.zabiny.club

The app is one static page served by nginx in a Docker container. Coolify builds the container from this repo; the host's own nginx terminates TLS and proxies to it.

```
browser ──HTTPS──> host nginx (certbot TLS) ──> 127.0.0.1:5100 ──> container (nginx:alpine, port 80)
                                                                    built by Coolify from this repo's Dockerfile
```

| Piece | Where |
|---|---|
| Code | `zabiny/track-pace`, branch `main` |
| Build | `Dockerfile` (copies `index.html`, `logo.svg`, `frog.svg` into nginx) |
| Coolify | https://cool.zabiny.club → project **tempo** → app **track-pace** |
| Host proxy | `/etc/nginx/conf.d/tempo.zabiny.club.conf` on the Coolify server |
| TLS | Let's Encrypt via `certbot --nginx`, auto-renewed by certbot's timer |
| DNS | DigitalOcean (the live nameservers for `zabiny.club`), record `tempo` → Coolify server |

## Normal update

1. Edit `index.html` (or the SVGs).
2. Check it locally: open `index.html` in a browser, including a narrow phone width (devtools device mode, 375 px).
3. Commit and push to `main`.
4. Deploy in Coolify, either:
   - **UI:** Coolify → tempo → track-pace → **Deploy**, or
   - **API:**
     ```sh
     curl -X POST -H "Authorization: Bearer $COOLIFY_TOKEN" \
       "https://cool.zabiny.club/api/v1/deploy?uuid=9gftjfumxqunwsqkdmd9fqf2"
     ```
     The response contains a `deployment_uuid`; poll
     `GET /api/v1/deployments/<deployment_uuid>` until `status` is `finished`.
5. Verify: open https://tempo.zabiny.club (reload; on iPhone pull down in Safari).

A deploy takes under a minute. If you add a new file the page needs, also add it to the `COPY` line in the `Dockerfile`.

## Rollback

`git revert` the bad commit, push, deploy again. Or in Coolify → track-pace → Deployments, redeploy an earlier build.

## First-time setup (already done, for reference)

1. **DNS:** in DigitalOcean add `tempo` as `CNAME azure.zabiny.club` (or `A` to the server IP). The Azure DNS zone for `zabiny.club` is not live — records there have no effect.
2. **Coolify app:** project `tempo`, public repository `https://github.com/zabiny/track-pace`, branch `main`, build pack **Dockerfile**, exposed port `80`, no domain (Coolify's own proxy is not used).
3. **Port mapping:** `127.0.0.1:5100:80`, so the container is reachable only from the host. Set it in Coolify UI → General → Port mappings (the API rejects the IP prefix).
4. **Host nginx vhost** `/etc/nginx/conf.d/tempo.zabiny.club.conf`:
   ```nginx
   server {
       listen 80;
       listen [::]:80;
       server_name tempo.zabiny.club;

       location / {
           proxy_pass http://127.0.0.1:5100;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
   then `sudo nginx -t && sudo systemctl reload nginx`.
5. **TLS:** `sudo certbot --nginx -d tempo.zabiny.club --redirect` (adds the 443 server block and the HTTP→HTTPS redirect).

## Troubleshooting

- **502 Bad Gateway:** container not running or not on 5100. On the server: `sudo docker ps | grep 5100`, `curl -I http://127.0.0.1:5100/`. Redeploy in Coolify.
- **Old version shown:** browser cache; reload. Check the deployment finished in Coolify.
- **Certificate errors:** `sudo certbot certificates`, `sudo certbot renew --dry-run`.
- **Name doesn't resolve:** `dig +short tempo.zabiny.club @ns1.digitalocean.com`.
