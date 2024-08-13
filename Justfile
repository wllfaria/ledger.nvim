default: lint fmt test

fmt:
  stylua lua/ --config-path=stylua.toml

lint:
  luacheck lua/ --globals vim

test:
  nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"
