{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.stylix) colors;

  # Custom Thonny package with Stylix theme plugin included
  thonnyWithStylix = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "thonny";
    version = "4.1.7";

    src = pkgs.fetchFromGitHub {
      owner = "thonny";
      repo = "thonny";
      tag = "v${version}";
      hash = "sha256-RnjnXB5jU13uwRpL/Pn14QY7fRbRkq09Vopc3fv+z+Y=";
    };

    nativeBuildInputs = [ pkgs.copyDesktopItems ];

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "Thonny";
        exec = "thonny";
        icon = "thonny";
        desktopName = "Thonny";
        comment = "Python IDE for beginners";
        categories = [
          "Development"
          "IDE"
        ];
      })
    ];

    dependencies = with pkgs.python3.pkgs; [
      jedi
      pyserial
      tkinter
      docutils
      pylint
      mypy
      pyperclip
      asttokens
      send2trash
      dbus-next
    ];

    # Create the thonnycontrib plugin directory with our Stylix theme
    postPatch = ''
            mkdir -p thonnycontrib
            echo "# Namespace package for Thonny plugins" > thonnycontrib/__init__.py
            cat > thonnycontrib/stylix_theme.py << 'PLUGIN'
      from thonny import get_workbench
      from thonny.workbench import SyntaxThemeSettings

      def stylix_syntax() -> SyntaxThemeSettings:
          """Syntax theme using Stylix/base16 colors."""
          default_fg = "#${colors.base05}"
          default_bg = "#${colors.base00}"
          string_fg = "#${colors.base0B}"
          open_string_bg = "#${colors.base01}"
          gutter_foreground = "#${colors.base04}"
          gutter_background = "#${colors.base01}"

          return {
              "TEXT": {
                  "foreground": default_fg,
                  "insertbackground": default_fg,
                  "background": default_bg,
              },
              "GUTTER": {"foreground": gutter_foreground, "background": gutter_background},
              "breakpoint": {"foreground": "#${colors.base08}"},
              "current_line": {"background": "#${colors.base01}"},
              "sel": {"foreground": "#${colors.base07}", "background": "#${colors.base02}"},
              "definition": {"foreground": "#${colors.base0D}"},
              "class_definition": {},
              "function_definition": {},
              "string": {"foreground": string_fg},
              "string3": {"foreground": string_fg, "background": None, "font": "EditorFont"},
              "open_string": {"foreground": string_fg, "background": open_string_bg},
              "open_string3": {
                  "foreground": string_fg,
                  "background": open_string_bg,
                  "font": "EditorFont",
              },
              "tab": {"background": "#${colors.base01}"},
              "builtin": {"foreground": "#${colors.base0C}"},
              "keyword": {"foreground": "#${colors.base0E}", "font": "BoldEditorFont"},
              "number": {"foreground": "#${colors.base09}"},
              "comment": {"foreground": "#${colors.base03}"},
              "welcome": {"foreground": "#${colors.base03}"},
              "magic": {"foreground": "#${colors.base0F}"},
              # shell
              "prompt": {"foreground": "#${colors.base0D}", "font": "BoldEditorFont"},
              "stdin": {"foreground": "#${colors.base0C}"},
              "stdout": {"foreground": default_fg},
              "stderr": {"foreground": "#${colors.base08}"},
              "value": {"foreground": "#${colors.base0A}"},
              "function_call": {},
              "method_call": {},
              "hyperlink": {"foreground": "#${colors.base0D}", "underline": True},
              "name_link": {"underline": True},
              # paren matcher
              "surrounding_parens": {"foreground": "#${colors.base0A}", "font": "BoldEditorFont"},
              "unclosed_expression": {"background": "#${colors.base02}"},
              # find/replace
              "found": {"underline": True},
              "current_found": {"foreground": "#${colors.base00}", "background": "#${colors.base0A}"},
              "matched_name": {"background": "#${colors.base02}"},
              "local_name": {"font": "ItalicEditorFont"},
              # debugger
              "active_focus": {"background": "#${colors.base0A}", "borderwidth": 1, "relief": "solid"},
              "suspended_focus": {"background": "", "borderwidth": 1, "relief": "solid"},
              "completed_focus": {"background": "#${colors.base0B}", "borderwidth": 1, "relief": "flat"},
              "exception_focus": {"background": "#${colors.base08}", "borderwidth": 1, "relief": "solid"},
              "expression_box": {"background": "#${colors.base02}", "foreground": default_fg},
              # ANSI colors
              "black_fg": {"foreground": "#${colors.base00}"},
              "black_bg": {"background": "#${colors.base00}"},
              "bright_black_fg": {"foreground": "#${colors.base03}"},
              "bright_black_bg": {"background": "#${colors.base03}"},
              "dim_black_fg": {"foreground": "#${colors.base00}"},
              "dim_black_bg": {"background": "#${colors.base00}"},
              "red_fg": {"foreground": "#${colors.base08}"},
              "red_bg": {"background": "#${colors.base08}"},
              "bright_red_fg": {"foreground": "#${colors.base08}"},
              "bright_red_bg": {"background": "#${colors.base08}"},
              "dim_red_fg": {"foreground": "#${colors.base08}"},
              "dim_red_bg": {"background": "#${colors.base08}"},
              "green_fg": {"foreground": "#${colors.base0B}"},
              "green_bg": {"background": "#${colors.base0B}"},
              "bright_green_fg": {"foreground": "#${colors.base0B}"},
              "bright_green_bg": {"background": "#${colors.base0B}"},
              "dim_green_fg": {"foreground": "#${colors.base0B}"},
              "dim_green_bg": {"background": "#${colors.base0B}"},
              "yellow_fg": {"foreground": "#${colors.base0A}"},
              "yellow_bg": {"background": "#${colors.base0A}"},
              "bright_yellow_fg": {"foreground": "#${colors.base0A}"},
              "bright_yellow_bg": {"background": "#${colors.base0A}"},
              "dim_yellow_fg": {"foreground": "#${colors.base0A}"},
              "dim_yellow_bg": {"background": "#${colors.base0A}"},
              "blue_fg": {"foreground": "#${colors.base0D}"},
              "blue_bg": {"background": "#${colors.base0D}"},
              "bright_blue_fg": {"foreground": "#${colors.base0D}"},
              "bright_blue_bg": {"background": "#${colors.base0D}"},
              "dim_blue_fg": {"foreground": "#${colors.base0D}"},
              "dim_blue_bg": {"background": "#${colors.base0D}"},
              "magenta_fg": {"foreground": "#${colors.base0E}"},
              "magenta_bg": {"background": "#${colors.base0E}"},
              "bright_magenta_fg": {"foreground": "#${colors.base0E}"},
              "bright_magenta_bg": {"background": "#${colors.base0E}"},
              "dim_magenta_fg": {"foreground": "#${colors.base0E}"},
              "dim_magenta_bg": {"background": "#${colors.base0E}"},
              "cyan_fg": {"foreground": "#${colors.base0C}"},
              "cyan_bg": {"background": "#${colors.base0C}"},
              "bright_cyan_fg": {"foreground": "#${colors.base0C}"},
              "bright_cyan_bg": {"background": "#${colors.base0C}"},
              "dim_cyan_fg": {"foreground": "#${colors.base0C}"},
              "dim_cyan_bg": {"background": "#${colors.base0C}"},
              "white_fg": {"foreground": "#${colors.base05}"},
              "white_bg": {"background": "#${colors.base05}"},
              "bright_white_fg": {"foreground": "#${colors.base07}"},
              "bright_white_bg": {"background": "#${colors.base07}"},
              "dim_white_fg": {"foreground": "#${colors.base04}"},
              "dim_white_bg": {"background": "#${colors.base04}"},
              "fore_fg": {"foreground": default_fg},
              "fore_bg": {"background": default_fg},
              "bright_fore_fg": {"foreground": "#${colors.base07}"},
              "bright_fore_bg": {"background": "#${colors.base07}"},
              "dim_fore_fg": {"foreground": "#${colors.base04}"},
              "dim_fore_bg": {"background": "#${colors.base04}"},
              "back_fg": {"foreground": default_bg},
              "back_bg": {"background": default_bg},
              "bright_back_fg": {"foreground": "#${colors.base01}"},
              "bright_back_bg": {"background": "#${colors.base01}"},
              "dim_back_fg": {"foreground": "#${colors.base00}"},
              "dim_back_bg": {"background": "#${colors.base00}"},
              "intense_io": {"font": "BoldIOFont"},
              "italic_io": {"font": "ItalicIOFont"},
              "intense_italic_io": {"font": "BoldItalicIOFont"},
              "underline": {"underline": True},
              "strikethrough": {"overstrike": True},
          }


      def stylix_ui():
          """UI theme using Stylix/base16 colors, based on clam theme."""
          from thonny.ui_utils import ems_to_pixels

          def scale(value) -> float:
              return get_workbench().scale(value / 1.67)

          # Base16 colors mapped to clam-style variables
          defaultfg = "#${colors.base05}"
          disabledfg = "#${colors.base03}"
          frame = "#${colors.base01}"
          window = "#${colors.base00}"
          dark = "#${colors.base02}"
          darker = "#${colors.base01}"
          darkest = "#${colors.base03}"
          lighter = "#${colors.base02}"
          selectbg = "#${colors.base0D}"
          selectfg = "#${colors.base00}"

          return [
              {
                  ".": {
                      "configure": {
                          "background": frame,
                          "foreground": defaultfg,
                          "bordercolor": darkest,
                          "darkcolor": dark,
                          "lightcolor": lighter,
                          "troughcolor": darker,
                          "selectbackground": selectbg,
                          "selectforeground": selectfg,
                          "selectborderwidth": 0,
                          "font": "TkDefaultFont",
                      },
                      "map": {
                          "background": [("disabled", frame), ("active", lighter)],
                          "foreground": [("disabled", disabledfg)],
                          "selectbackground": [("!focus", darkest)],
                          "selectforeground": [("!focus", "#${colors.base05}")],
                      },
                  },
                  "TButton": {
                      "configure": {
                          "anchor": "center",
                          "width": scale(11),
                          "padding": scale(5),
                          "relief": "raised",
                      },
                      "map": {
                          "background": [("disabled", frame), ("pressed", darker), ("active", lighter)],
                          "lightcolor": [("pressed", darker)],
                          "darkcolor": [("pressed", darker)],
                          "bordercolor": [("alternate", "#${colors.base0D}")],
                      },
                  },
                  "Toolbutton": {
                      "configure": {"anchor": "center", "padding": scale(2), "relief": "flat"},
                      "map": {
                          "relief": [
                              ("disabled", "flat"),
                              ("selected", "sunken"),
                              ("pressed", "sunken"),
                              ("active", "raised"),
                          ],
                          "background": [("disabled", frame), ("pressed", darker), ("active", lighter)],
                          "lightcolor": [("pressed", darker)],
                          "darkcolor": [("pressed", darker)],
                      },
                  },
                  "CustomToolbutton": {
                      "configure": {"background": frame, "activebackground": darker, "foreground": defaultfg}
                  },
                  "CustomNotebook": {
                      "configure": {
                          "bordercolor": darker,
                      }
                  },
                  "CustomNotebook.Tab": {
                      "configure": {
                          "background": darker,
                          "activebackground": frame,
                          "hoverbackground": frame,
                          "indicatorbackground": frame,
                      }
                  },
                  "TCheckbutton": {
                      "configure": {
                          "indicatorbackground": window,
                          "indicatormargin": [scale(1), scale(1), scale(6), scale(1)],
                          "padding": scale(2),
                      },
                      "map": {
                          "indicatorbackground": [
                              ("pressed", frame),
                              ("!disabled", "alternate", selectbg),
                              ("disabled", "alternate", disabledfg),
                              ("disabled", frame),
                          ]
                      },
                  },
                  "TRadiobutton": {
                      "configure": {
                          "indicatorbackground": window,
                          "indicatormargin": [scale(1), scale(1), scale(6), scale(1)],
                          "padding": scale(2),
                      },
                      "map": {
                          "indicatorbackground": [
                              ("pressed", frame),
                              ("!disabled", "alternate", selectbg),
                              ("disabled", "alternate", disabledfg),
                              ("disabled", frame),
                          ]
                      },
                  },
                  "TMenubutton": {"configure": {"width": scale(11), "padding": scale(5), "relief": "raised"}},
                  "TEntry": {
                      "configure": {"padding": scale(1), "insertwidth": scale(1)},
                      "map": {
                          "background": [("readonly", frame)],
                          "bordercolor": [("focus", selectbg)],
                          "lightcolor": [("focus", selectbg)],
                          "darkcolor": [("focus", selectbg)],
                      },
                  },
                  "TCombobox": {
                      "configure": {
                          "padding": [scale(4), scale(2), scale(2), scale(2)],
                          "insertwidth": scale(1),
                      },
                      "map": {
                          "background": [("active", lighter), ("pressed", lighter)],
                          "fieldbackground": [("readonly", "focus", selectbg), ("readonly", frame)],
                          "foreground": [("readonly", "focus", selectfg)],
                          "arrowcolor": [("disabled", disabledfg)],
                      },
                  },
                  "ComboboxPopdownFrame": {"configure": {"relief": "solid", "borderwidth": scale(1)}},
                  "TSpinbox": {
                      "configure": {"arrowsize": scale(10), "padding": [scale(2), 0, scale(10), 0]},
                      "map": {"background": [("readonly", frame)], "arrowcolor": [("disabled", disabledfg)]},
                  },
                  "TNotebook.Tab": {
                      "configure": {"padding": [scale(6), scale(2), scale(6), scale(2)]},
                      "map": {
                          "padding": [("selected", [scale(6), scale(4), scale(6), scale(4)])],
                          "background": [("selected", frame), ("", darker)],
                          "lightcolor": [("selected", lighter), ("", dark)],
                      },
                  },
                  "Treeview": {
                      "configure": {"background": window},
                      "map": {
                          "background": [
                              ("disabled", frame),
                              ("!disabled", "!selected", window),
                              ("selected", selectbg),
                          ],
                          "foreground": [
                              ("disabled", disabledfg),
                              ("!disabled", "!selected", defaultfg),
                              ("selected", selectfg),
                          ],
                      },
                  },
                  "Heading": {
                      "configure": {
                          "font": "TkHeadingFont",
                          "relief": "raised",
                          "padding": [scale(3), scale(3), scale(3), scale(3)],
                      }
                  },
                  "TLabelframe": {"configure": {"labeloutside": True, "labelmargins": [0, 0, 0, scale(4)]}},
                  "TProgressbar": {"configure": {"background": "#${colors.base0D}"}},
                  "Sash": {"configure": {"sashthickness": ems_to_pixels(0.6), "gripcount": 10}},
                  "Text": {
                      "configure": {
                          "background": window,
                          "foreground": defaultfg,
                      }
                  },
                  "Gutter": {"configure": {"background": "#${colors.base01}", "foreground": "#${colors.base04}"}},
                  "Url.TLabel": {"configure": {"foreground": "#${colors.base0D}"}},
                  "Tip.TLabel": {"configure": {"background": "#${colors.base02}", "foreground": defaultfg}},
                  "Tip.TFrame": {"configure": {"background": "#${colors.base02}"}},
                  "Listbox": {
                      "configure": {
                          "background": window,
                          "foreground": defaultfg,
                          "disabledforeground": disabledfg,
                          "highlightbackground": selectbg,
                          "highlightcolor": selectbg,
                          "highlightthickness": 0,
                      }
                  },
                  "ViewTab.TLabel": {"configure": {"padding": [scale(5), 0]}},
                  "Active.ViewTab.TLabel": {
                      "configure": {
                          "relief": "sunken",
                          "borderwidth": scale(1),
                      }
                  },
                  "Inactive.ViewTab.TLabel": {"map": {"relief": [("hover", "raised")]}},
                  "TextPanedWindow": {"configure": {"background": window}},
              }
          ]


      def load_plugin():
          get_workbench().add_syntax_theme("Stylix", "Default Dark", stylix_syntax)
          get_workbench().add_ui_theme("Stylix", "clam", stylix_ui)
      PLUGIN
    '';

    preFixup = ''
      wrapProgram "$out/bin/thonny" \
         --prefix PYTHONPATH : $PYTHONPATH:$(toPythonPath ${pkgs.python3.pkgs.jedi})
    '';

    postInstall = ''
      install -Dm644 ./packaging/icons/thonny-48x48.png $out/share/icons/hicolor/48x48/apps/thonny.png
    '';

    doCheck = false;

    meta = {
      description = "Python IDE for beginners";
      homepage = "https://www.thonny.org/";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "thonny";
    };
  };
in
{
  home.packages = [ thonnyWithStylix ];
}
