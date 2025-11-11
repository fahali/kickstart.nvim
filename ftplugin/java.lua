local jdtls = require 'jdtls'

-- root_markers enumerates filenames in a Java project's root directory
-- jdtls uses this to determine a workspace
local root_markers = { '.git', 'build.gradle', 'gradlew', 'mvnw', 'pom.xml', '.classpath' }
local root_dir = require('jdtls.setup').find_root(root_markers)

-- set a storage location for project specific data; must be unique across different projects
local workspace_dir = os.getenv 'HOME' .. '/.local/share/eclipse/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')

local on_attach = function(_, buffer)
  local mk_opts = function(desc)
    return { noremap = true, silent = true, buffer = buffer, desc = desc }
  end

  vim.keymap.set({ 'n' }, 'oi', jdtls.organize_imports, mk_opts '[O]rganize [I]mports')
  vim.keymap.set({ 'n' }, '<leader>ev', jdtls.extract_variable, mk_opts '[E]xtract [V]ariable')
  vim.keymap.set({ 'n' }, '<leader>ec', jdtls.extract_constant, mk_opts '[E]xtract [C]onstant')
  vim.keymap.set({ 'n', 'v' }, '<leader>em', jdtls.extract_method, mk_opts '[E]xtract [M]ethod')
  vim.keymap.set({ 'n' }, '<leader>vc', jdtls.test_class, mk_opts 'Test class (DAP)')
  vim.keymap.set({ 'n' }, '<leader>vm', jdtls.test_nearest_method, mk_opts 'Test method (DAP)')

  require('jdtls').setup_dap { hotcodereplace = 'auto' }
end

local bundles = {
  vim.fn.glob '~/Development/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar',
}

vim.list_extend(bundles, vim.split(vim.fn.glob('~/Development/vscode-java-test/server/*.jar', true), '\n'))

local config = {
  flags = {
    debounce_text_changes = 80,
  },
  on_attach = on_attach,
  init_options = {
    bundles = bundles,
  },
  root_dir = root_dir,
  settings = {
    java = {
      format = {
        settings = {
          -- NOTE: formatting / checkstyle
          url = '/.local/share/eclipse/eclipse-java-google-style.xml',
          profile = 'GoogleStyle',
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = {
        -- Decompiler for library code
        preferred = 'fernflower',
      },
      -- NOTE: autocomplete
      completion = {
        favoriteStaticMembers = {
          'org.hamcrest.MatcherAssert.assertThat',
          'org.hamcrest.Matchers.*',
          'org.hamcrest.CoreMatchers.*',
          'org.junit.jupiter.api.Assertions.*',
          'java.util.Objects.requireNonNull',
          'java.util.Objects.requireNonNullElse',
          'org.mockito.Mockito.*',
        },
        filteredTypes = {
          'com.sun.*',
          'io.micrometer.shaded.*',
          'java.awt.*',
          'jdk.*',
          'sun.*',
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 10,
          staticStarThreshold = 10,
        },
      },
      codeGeneration = {
        toString = {
          template = '${object.className}{${member.name()}=${member.value}, ${otherMembers}}',
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },

      -- NOTE: when developing with multiple JDKs, we need to configure them below.
      -- See: https://github.com/eclipse-jdtls/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- 'enum ExecutionEnvironment' provides 'name'
      -- point to the JDK with 'path'

      --[[
      configuration = {
        runtimes = {
          {
            name = 'ExampleJavaSE',
            path = home .. '/path/to/jdk',
          },
        },
      },
      --]]
    },
  },

  -- NOTE: start the Java language server
  cmd = {
    os.getenv 'JAVA_HOME' .. '/bin/java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx4g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',

    '-jar',
    vim.fn.glob '/opt/homebrew/Cellar/jdtls/1.52.0/libexec/plugins/org.eclipse.equinox.launcher_*.jar',

    '-configuration',
    '/opt/homebrew/Cellar/jdtls/1.52.0/libexec/config_mac/',
    '-data',
    workspace_dir,
  },
}

jdtls.start_or_attach(config)
