Plug 'godlygeek/tabular'
Plug 'fladson/vim-kitty'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
Plug 'airblade/vim-gitgutter'
Plug 'scrooloose/nerdcommenter'
Plug 'sheerun/vim-polyglot', {'commit': '4d4aa5fe553a47ef5c5c6d0a97bb487fdfda2d5b'}
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'dyng/ctrlsf.vim'
Plug 'Yggdroot/indentLine'
Plug 'benmills/vimux'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tklepzig/vim-buffer-navigator'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-abolish'
Plug 'mracos/mermaid.vim'
Plug 'markonm/traces.vim'
Plug 'github/copilot.vim'
"Needs a vaild OpenAI key
"Plug 'madox2/vim-ai'
Plug 'wellle/context.vim'
Plug 'CopilotC-Nvim/CopilotChat.nvim', !empty($DOTFILES_NVIM) && has('nvim') ? {} : { 'on': [] }
Plug 'nvim-lua/plenary.nvim', !empty($DOTFILES_NVIM) && has('nvim') ? {} : { 'on': [] }
Plug 'samoshkin/vim-mergetool'
Plug 'rhysd/conflict-marker.vim'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'alvan/vim-closetag'
Plug 'janko/vim-test'
Plug 'thinca/vim-themis'

" markdown & Co
Plug 'junegunn/goyo.vim'
Plug 'junegunn/seoul256.vim'
Plug 'junegunn/limelight.vim'
Plug 'plasticboy/vim-markdown'
Plug 'mzlogin/vim-markdown-toc'
Plug 'lervag/vimtex'

" ruby
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-projectionist'
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'
