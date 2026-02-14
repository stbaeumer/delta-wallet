![Screenshots of Found ICE showing a form that can be filled out and a message that was made from the form that you can send to people.](banner.png)

# 🧊 Found ICE

Found ICE is a tool to write down a possible ICE sighting using the SALUTE template (size, activity, location, uniform, time, equipment) and send it to those opposing ICE in the area. This is an app for [Delta Chat](https://delta.chat/en/).

You can get it on [itch.io](https://durianbean.itch.io/found-ice), [webxdc.org](https://webxdc.org/apps/#found-ice), or in the [release page](https://codeberg.org/durian/found-ice/releases)! 

[![Available on itch.io button](itch.png)](https://durianbean.itch.io/found-ice)

## License

This is [anti-capitalist software](https://anticapitalist.software/), released for free use by individuals and organizations that do not operate by capitalist principles.

### Contains bits and pieces of the following projects:

Please support them if you can!

- [Fennel](https://fennel-lang.org/): Programming language that runs on the Lua runtime (MIT License) (version 1.5.3)
- [Fengari](https://github.com/fengari-lua/fengari): Lua VM written in JS (MIT License) (version v0.1.4)
- [Pico CSS](https://picocss.com/): A minimalist and lightweight starter kit (MIT License) (version v2.1.1)
- [Solar icon set](https://icon-sets.iconify.design/solar/) (CC BY 4.0 License)
- [RetroV](https://ratfactor.com/retrov/): Virtual DOM rendering library (MIT License) (commit 3fed42e)

## Introduction for devs

This app is written in [Fennel](https://fennel-lang.org/) which is compiled into [Lua](https://www.lua.org/) which then runs on [Fengari](https://github.com/fengari-lua/fengari/) which is a Lua VM written in JavaScript. Now why are we standing on the computer language equivalent of the [Tower of Babel](https://en.wikipedia.org/wiki/Tower_of_Babel)? Because it's fun to write in Fennel and I wanted it to run on the browser!

### How to build

#### Prerequisites

Ok this is kind of an annoying part, but bear with me. We need to get you some of the tools that we need to build this project. 

- [Lua](https://www.lua.org/) is used to run the Fennel compiler. Since Fengari is compatible with Lua 5.3, we should install 5.3 on our system.
- [Fennel](https://fennel-lang.org/) is used to compile our code into Lua.
- [LuaFileSystem](https://lunarmodules.github.io/luafilesystem/) is used to check for any file changes.
- [luaposix](https://github.com/luaposix/luaposix) is used to pause the program while waiting for changes.
- [Zip](https://infozip.sourceforge.net/Zip.html) compresses our app and creates the `.xdc` file.

Installing these tools vary between different operating systems (there's so many of them!), but I've tried it on the following systems. Here's how you can install Lua and its dependencies:

<details>

<summary><b>Debian-based (Linux Mint, Ubuntu, etc.)</b></summary>

##### Debian

Install Lua, the Lua libraries, and zip.

```
$ sudo apt install lua5.3 lua-filesystem zip lua-posix
```

After that, install the [Fennel executable](https://fennel-lang.org/setup#downloading-the-fennel-script).

</details>

<details>

<summary><b>OpenBSD</b></summary>

##### OpenBSD

Thankfully, everything we need are a part of the package manager!

```
$ doas pkg_add fennel-lua53 lua53fs lua53posix zip
```

</details>

#### Building

So after installing those tools, what we need to do to build is to `cd` into the directory and run:

```
$ fennel build.fnl
```

This compiles our Fennel program into Lua and bundles everything else into an `index.html` file. There's nothing else to do after that, really! You'll find that there's a `dist/time.xdc` file that's also ready to go. Drag and drop that file into Delta Chat, and you're done! You can also view the app by opening `index.html` in your browser.

---

## Technical deets

This is a deep dive into the inner workings of the app. This is mostly for me because I'm likely to forget how this app works in the future, but if something is not clear let me know!

### Useful hacking tools

When I started this project, I was using Sublime Text with [sublime-text-fennel](https://github.com/gbaptista/sublime-text-fennel), but I find that it's much nicer to use Emacs with [fennel-mode](https://git.sr.ht/~technomancy/fennel-mode) and [rainbow-delimiters](https://github.com/Fanael/rainbow-delimiters) when working with Fennel. It takes some getting used to, but it feels worth it.

It's also good to have the `fennel` executable in your path so that you can use `M-x fennel-repl` within Emacs as well. 

### Build process

Let's start with the `fennel build.fnl` file. This runs on the Lua runtime on your machine and it generates a single `index.html` file that includes:

- Fennel files compiled to Lua in a `<script>` tag.
- JS added into a `<script>` tags.
- CSS added into `<style>` tags.

The HTML is represented as a Lua table in `index.fnl` which `build.fnl` reads and writes an HTML string into `index.html`. Inside the Lua table you'll find a function call to `build.load-assets` that's defined in `build-helpers.fnl`. This takes a sequential table (array in other languages) which has the files that we want to include, the filetype, and whether we want to inline it or not.

```fennel
(fn load-assets [assets]
  (table.unpack
   (icollect [_ [asset filetype inline] (ipairs assets)]
     (if inline
         (case filetype
           :js   [:script {} (read-file asset)]
           :css  [:style {} (read-file asset)]
           :lua  [:script {:type "application/lua"} (read-file asset)])
         (case filetype
           :js   [:script {:src asset :type "text/javascript"}]
           :css  [:link {:rel "stylesheet" :href asset :type "text/css"}]
           :lua  [:script {:src asset :type "application/lua" :async true}])))))
```

It also reads and compiles our Fennel files into Lua which is written inside `index.html` and also `main.lua`. The files that we want to build are in the `files` table. Finally, it creates a zip file called `dist/time.xdc` which we can then share with other people.

```fennel
;; Create our webxdc app
(let [commands ["mkdir -p dist"
                "rm -rf dist/time.xdc"
                "zip -9 --recurse-paths dist/salute.xdc index.html icon.jpg manifest.toml"]]
  (each [_ cmd (ipairs commands)]
    (print "Command" cmd)
    (os.execute cmd)))
```

Additionally, `build.fnl` also watches for file changes and re-runs the whole build process automatically! To quit, simply press Ctrl+C.
