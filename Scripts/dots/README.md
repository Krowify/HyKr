# dots

One `.toml` manifest per app, mapping its dotfiles in `Configs/configs/`
to their destination under `$HOME`:

```toml
[appname]
source = "Configs/configs/appname"
target = "~/.config/appname"
```

Read and linked by [`../link_dots.sh`](../link_dots.sh) — add a new
`.toml` here whenever a new app's config is added to `Configs/`.
