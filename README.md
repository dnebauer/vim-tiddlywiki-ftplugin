# TiddlyWiki Tiddler Filetype Plugin for Vim #

This is a fork of Devin Weaver's
[sukima/vim-tiddlywiki](https://github.com/sukima/vim-tiddlywiki) GitHub
project providing a TiddlyWiki support plugin, which itself is a fork of
Swaroop C H's original [vim syntax
file](https://www.vim.org/scripts/script.php?script_id=2705) for TiddlyWiki
markup.

[TiddlyWiki](https://tiddlywiki.com) is a non-linear notebook, or wiki. The
basis of TiddlyWiki is capturing information into the smallest possible
semantically meaningful units, called "tiddlers," and aggregating them in
meaningful ways to present narrative stories.

From version 5 of TiddlyWiki each tiddler is stored in its own file, which has
a `tid` extension. This filetype plugin defines the "tiddlywiki" filetype for
these files and provides a syntax file for this filetype, as well as some
useful commands and mappings (see [plugin
help](doc/ft-tiddlywiki-plugin.txt) for further details).

## Changes from original project ##

For those familiar with Devin Weaver's
[sukima/vim-tiddlywiki](https://github.com/sukima/vim-tiddlywiki) plugin, in
this fork internal changes include:

* Moving functions into an autoload library
* Using the file layout recommended by the
  [google/vimdoc](https://github.com/google/vimdoc) project
* Adding more error checking to increase robustness (particularly with
  obtaining the system datetime).

The following changes have been made to the user interface:

* The `<Leader>tt` mapping for initialising tiddler files is now `<Leader>ti`
* Added commands `TWInitialiseTiddler` and `TWUpdateModificationTime`,
  corresponding to the two available mappings
* Added a documentation/help file

## Installation ##

Follow the installation instructions of your plugin manager.

## License ##

This fork has inherited the [Apache 2.0
License](http://www.apache.org/licenses/LICENSE-2.0.txt) from the
[sukima/vim-tiddlywiki](https://github.com/sukima/vim-tiddlywiki) project.
