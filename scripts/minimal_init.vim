let plenary_path = getenv('PLENARY_PATH')
let luasnip_path = getenv('LUASNIP_PATH')
let nvim_cmp_path = getenv('CMP_PATH')
let nvim_treesitter_path = getenv('TREESITTER_PATH')

function! s:maybe_get_from_lazy(plugin_path, plugin_name)
  let nvim_dir = expand('~/.local/share/nvim')
  let inner_path = a:plugin_path
  if inner_path == v:null
    let lazy_path = nvim_dir . '/lazy'
    if isdirectory(lazy_path)
      let inner_path = lazy_path . '/' . a:plugin_name
    else
      let inner_path = '../' . a:plugin_name
    endif
  endif
  return inner_path
endfunction

set rtp+=.
execute 'set rtp+=' . s:maybe_get_from_lazy(plenary_path, 'plenary.nvim')
execute 'set rtp+=' . s:maybe_get_from_lazy(luasnip_path, 'LuaSnip')
execute 'set rtp+=' . s:maybe_get_from_lazy(nvim_cmp_path, 'nvim-cmp')
execute 'set rtp+=' . s:maybe_get_from_lazy(nvim_treesitter_path, 'nvim-treesitter')

runtime! plugin/plenary.vim
runtime! plugin/LuaSnip
runtime! plugin/nvim-cmp
runtime! plugin/nvim-treesitter
