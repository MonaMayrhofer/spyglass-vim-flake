{
  inputs.neovim-flake = {
    url = "github:notashelf/neovim-flake";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.nvim-lspconfig.url = "github:neovim/nvim-lspconfig?ref=873eaf34b8a9056070d0dd2c63b5a1a914ca8d1f";
  };

  outputs = {
    nixpkgs,
    neovim-flake,
    ...
  }: let
    spyglass = pkgs.buildNpmPackage {
      pname = "@spyglassmc/language-server";
      version = "0.4.2";

      src = builtins.path {
        name = "spyglass-server";
        path = ./lang-server;
      };
      npmDepsHash = "sha256-klEATxczHBanZBqDk82ilWcRNBxsKZwAlutus7lGOjE=";
      dontNpmBuild = true;

      # The prepack script runs the build script, which we'd rather do in the build phase.
      npmPackFlags = ["--ignore-scripts"];
      npmFlags = ["--legacy-peer-deps"];
      makeCacheWritable = true;
      NODE_OPTIONS = "--openssl-legacy-provider";
    };

    vim-mcfunction = pkgs.fetchFromGitHub {
      owner = "CrystalAlpha358";
      repo = "vim-mcfunction";
      rev = "074aa25dd3128bb9de174e7e7039c3c76bbe5fb4";
      hash = "sha256-8fe1/xPcDH7NtniWXVr6UIMYu7gxfihpQ92IPesevl8=";
    };

    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    configModule = {
      # Add any custom options (and feel free to upstream them!)
      # options = ...

      config.vim = {
        theme.enable = true;
        lsp.lspconfig = {
          enable = true;
          #cmd = {"${spyglass}/bin/datapack-language-servers","--stdio"}
          sources.minecraft = pkgs.lib.debug.traceVal ''
            require'lspconfig'.spyglassmc_language_server.setup{
              cmd = {"${spyglass}/bin/spyglassmc-language-server","--stdio"}
            }
          '';
        };
        extraPlugins = with pkgs.vimPlugins; {
          mcfunction = {
            package = vim-mcfunction;
            after = ["nvim-lspconfig"];
          };
        };

        lsp = {
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          nvimCodeActionMenu.enable = true;
          trouble.enable = true;
          lspSignature.enable = true;
          lsplines.enable = true;
          nvim-docs-view.enable = true;
        };

        visuals = {
          enable = true;
          nvimWebDevicons.enable = true;
          scrollBar.enable = true;
          smoothScroll.enable = true;
          cellularAutomaton.enable = false;
          fidget-nvim.enable = true;
          highlight-undo.enable = true;

          indentBlankline = {
            enable = true;
            fillChar = null;
            eolChar = null;
            scope = {
              enabled = true;
            };
          };

          cursorline = {
            enable = true;
            lineTimeout = 0;
          };
        };

        statusline = {
          lualine = {
            enable = true;
            theme = "dracula";
          };
        };
        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        autocomplete = {
          enable = true;
          type = "nvim-cmp";
          mappings = {
            next = "<C-j>";
            previous = "<C-k>";
            close = "<C-h>";
          };
        };

        filetree = {
          nvimTree = {
            enable = true;
            mappings = {
              toggle = "<leader>e";
            };
          };
        };

        telescope = {
          enable = true;
          mappings = {
            findFiles = "<C-p>";
          };
        };
      };
    };

    customNeovim = neovim-flake.lib.neovimConfiguration {
      modules = [configModule];
      inherit pkgs;
    };
  in {
    # this will make the package available as a flake input
    packages.${system} = {
      spyglass = spyglass;
      neovim = customNeovim.neovim;
    };

    # this is an example nixosConfiguration using the built neovim package
    nixosConfigurations = {
      yourHostName = nixpkgs.lib.nixosSystem {
        # ...
        modules = [
          ./configuration.nix # or whatever your configuration is

          # this will make wrapped neovim available in your system packages
          {environment.systemPackages = [customNeovim.neovim];}
        ];
        # ...
      };
    };
  };
}
