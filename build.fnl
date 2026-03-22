;; A little build system for this project

(local fennel (require :fennel))
(local build (require :build-helpers))
(local posix (require :posix))

;; Let's do some building!
;;
;; - Compiles Fennel files into Lua
;; - Creates HTML files from Lua tables
;; - Creates our Webxdc file
;;
;; This also automatically checks if there are any changes to
;; our files by polling them for any changes every second

(let [;; These are the files that we want to build
      files    [{:file "main"  :from "fnl" :to "lua" }
                {:file "index" :from "fnl" :to "html"}]

      ;; These are the commands that we want to run
      cmds     ["mkdir -p dist"
                "rm -rf dist/*"
                "zip -9 -r dist/delta-wallet.xdc index.html icon.png manifest.toml assets/pico.indigo.min.css style.css libs/retrov.min.js libs/fengari-web.js main.lua"]

      ;; These are the files that we want to watch
      ;; (not recursive, only the current directory is watched)
      modified (build.files-modified [:fnl :css :js])]
  
  (fn build-loop []
    ;; Rebuild the files whenever they're modified
    (when (modified)
      
      (print "\n 🔄 Rebuilding files ...\n")
      (each [_ { : file : from : to } (ipairs files)]
        (case to          
          ;; Load the Lua table then write it into a file
          ;; index.fnl -> index.html
          :html
          (let [contents (fennel.dofile (.. file "." from))]
            (build.write-html (.. file "." to)
                              (contents.html build)))

          ;; Load the Fennel files and compile them into Lua
          ;; main.fnl -> main.lua
          :lua
          (case (io.open (.. file "." from) :r)
            f (let [(ok luaSource) (pcall #(fennel.compile f {:requireAsInclude true}))]
                (case ok
                  true (build.write-lua (.. file "." to) luaSource)
                  false (print luaSource))
                (f:close))
            (nil err) (print "Could not read" (.. file "." from) err))))

      ;; Create our webxdc app
      (each [_ cmd (ipairs cmds)]
        (print "Command" cmd)
        (os.execute cmd)))

    ;; Let's pause the program for a bit
    (coroutine.yield)
    (build-loop))
  
  (let [co (coroutine.create build-loop)]
    (while true
      (coroutine.resume co)
      ;; We can use (os.clock) but that seems to consume
      ;; quite a bit of CPU. Sleep seems much more efficient.
      (posix.sleep 1))))


