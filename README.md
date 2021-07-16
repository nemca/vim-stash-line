# vim-stash-line

A Vim plugin that opens a link to the current line on Bitbucket.

## How to install

Put this in your .vimrc
```
Plugin 'nemca/vim-stash-line'
```
Then restart vim and run `:PluginInstall`.
To update the plugin to the latest version, you can run `:PluginUpdate`.

## How to use

Default key mapping for a blob view: `<leader>st`.

Use your own mappings:
```
let g:stash_line_map = '<leader>st'
```

## Debugging

For getting verbose prints from vim-stash-line plugin set.
```
let g:stash_line_trace = 1
```
