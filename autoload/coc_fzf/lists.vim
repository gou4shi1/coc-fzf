" description: coc-fzf available list sources

let s:prompt = 'Coc Lists> '

function! coc_fzf#lists#fzf_run(range, ...) abort
  let s:list_sources = coc_fzf#common#get_list_sources()
  if a:0 && a:1[0] != '-'
    " execute one source/list
    let src = a:000[0]
    " append range to arguments
    let src_opts = a:000[1:]
    call s:run_source(src, a:range, src_opts)
  else
    " prompt all available lists
    let list_opt = a:0 ? a:1 : ''
    call coc_fzf#common#log_function_call(expand('<sfile>'), a:000)
    let expect_keys = coc_fzf#common#get_default_file_expect_keys()
    let opts = {
          \ 'source': s:get_lists(list_opt),
          \ 'sink*': function('s:list_handler', [a:range]),
          \ 'options': ['--expect='.expect_keys,
          \ '--ansi', '--prompt=' . s:prompt] + g:coc_fzf_opts,
          \ }
    call fzf#run(fzf#wrap(opts))
  endif
endfunction

function s:run_source(src, range, ...) abort
  let src_opts = a:0 ? a:1 : []
  if index(sort(keys(s:list_sources)), a:src) < 0
    call coc_fzf#common#echom_error('List ' . a:src . ' does not exist')
    return
  endif
  let wrapper = s:list_sources[a:src].wrapper
  if wrapper == v:null
    call call('coc_fzf#' . a:src . '#fzf_run', src_opts + [a:range])
  else
    let str_opts = empty(src_opts) ? '' : ' ' . join(src_opts)
    let cmd = wrapper . str_opts
    call coc_fzf#common#log_function_call('execute', [cmd])
    if g:coc_fzf_command_delay > 0
      call timer_start(g:coc_fzf_command_delay, { -> execute(cmd)})
    else
      execute cmd
    endif
  endif
endfunction

function s:get_lists(list_opt) abort
  let lists_with_color = []
  for src in sort(keys(s:list_sources))
    if a:list_opt == '--original-only' && s:list_sources[src].wrapper != v:null
      continue
    endif
    let description = s:list_sources[src].description
    let description = description != v:null ? description : ''
    let wrapper = s:list_sources[src].wrapper == v:null ? '' : '[wrapper]'
    let lists_with_color += [printf("%s %s %s",
          \ src,
          \ coc_fzf#common_fzf_vim#green(description, 'Comment'),
          \ coc_fzf#common_fzf_vim#yellow(wrapper, 'Special')
          \ )]
  endfor
  return lists_with_color
endfunction

function! s:list_handler(range, list) abort
  if empty(a:list)
    return
  endif
  let src = split(a:list[1])[0]
  if !empty(src)
    call s:run_source(src, a:range)
  endif
endfunction
