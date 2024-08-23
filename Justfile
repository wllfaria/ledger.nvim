default: lint fmt test

fmt:
  stylua lua/ --config-path=stylua.toml

lint:
  # 4** is shadowing warnings on luacheck
  luacheck lua/ --globals vim --ignore 4*

test:
  nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory lua/tests/ { minimal_init = './scripts/minimal_init.vim' }"
