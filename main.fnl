;; JS interop
(local {:global { : document
                  : navigator
                  : webxdc } &as js} (require :js))
(local log (fn [...] (js.global.console:log ...)))

;; HTML library
(local { : render
         : RV } (require :html))

;; Internationalization
(local i18n (require :i18n))

;; Add icons
(local icons (require :icons))

(local app {})
(local state {:files [] :qrcode-data nil :qrcode-file nil})

;; This creates the header of the app
(render [:div {:class "container"}
         [:nav {}
          [:ul {}
           [:li {}
            [:div {:id "title"}
             [:b {} "💳 Delta Wallet"]]]]]] "#nav")

;; Check if the input fields are filled or not.
(fn is-empty? [key]
  (or (= (?. RV.id key :value) nil) (= (?. RV.id key :value) "")))

;; Check if any required field is filled
(fn form-has-content? []
  (or (not (is-empty? :title))
      (not (is-empty? :description))
      (not (is-empty? :url))
      (not= state.qrcode-data nil)
      (not (is-empty? :datetime))
      (> (# state.files) 0)))

;; Reset the form
(fn reset []
  (each [_ v (ipairs [:title :description :url :datetime])]
    (if (not (is-empty? v))
        (set (. RV.id v :value) "")))
  (set state.files [])
  (set state.qrcode-data nil)
  (set state.qrcode-file nil)
  (app.render))

;; Read a QR-Code image file and store as data URL
(fn read-qr-code [el]
  (let [file (. el.files 0)]
    (if file
        (do
          (set state.qrcode-file file)
          (let [reader (js.new js.global.FileReader)]
            (set reader.onload (fn [ev]
                                 (set state.qrcode-data ev.target.result)
                                 (app.render)))
            (reader:readAsDataURL file)))
        (do
          (set state.qrcode-file nil)
          (set state.qrcode-data nil)
          (app.render)))))

;; Collect selected files into state
(fn update-files [el]
  (set state.files [])
  (let [flist el.files
        n     (. flist :length)]
    (for [i 0 (- n 1)]
      (table.insert state.files (. flist i))))
  (app.render))

(fn input-template [id placeholder-key description-key]
  [:div {}
   [:input {:id id
            :rvid id
            :type "text"
            :placeholder (i18n.text placeholder-key)
            :oninput (fn [el] (app.render))}]
   [:small {} (i18n.text description-key)]])

(fn textarea-template [id placeholder-key description-key]
  [:div {}
   [:textarea {:id id
               :rvid id
               :placeholder (i18n.text placeholder-key)
               :oninput (fn [el] (app.render))}]
   [:small {} (i18n.text description-key)]])

(fn send-to-chat []
  (let [text-obj    (js.new js.global.Object)
        title       (if (is-empty? :title) "Wallet Entry" RV.id.title.value)
        description (if (is-empty? :description) "" RV.id.description.value)
        url         (if (is-empty? :url) "" RV.id.url.value)
        datetime    (if (is-empty? :datetime) "" RV.id.datetime.value)
        file-names  (if (> (# state.files) 0)
                        (table.concat
                          (icollect [_ f (ipairs state.files)] f.name)
                          ", ")
                        "")]
    ;; 1) Send wallet details as text message.
    (set (. text-obj :text) (.. "💳 " title
                                (if (= description "") "" (.. "\n\n" description))
                                (if (= url "") "" (.. "\n\n🔗 " url))
                                (if (= datetime "") "" (.. "\n\n📅 " datetime))
                                (if (= file-names "") "" (.. "\n\n📎 " file-names))))
    (webxdc:sendToChat text-obj)

    ;; 2) Send QR image as real attachment so Delta Chat can render it.
    (when state.qrcode-file
      (let [qr-obj (js.new js.global.Object)]
        (set (. qr-obj :text) "QR-Code")
        (set (. qr-obj :file) state.qrcode-file)
        (set (. qr-obj :name) (or state.qrcode-file.name "qrcode.png"))
        (set (. qr-obj :filename) (or state.qrcode-file.name "qrcode.png"))
        (webxdc:sendToChat qr-obj)))

    ;; 3) Send each uploaded file as its own attachment message.
    (each [_ file (ipairs state.files)]
      (let [file-obj (js.new js.global.Object)
            fname    (or file.name "attachment")]
        (set (. file-obj :text) (.. "Anhang: " fname))
        (set (. file-obj :file) file)
        (set (. file-obj :name) fname)
        (set (. file-obj :filename) fname)
        (webxdc:sendToChat file-obj)))))

;; Render function for rendering the whole page
(fn app.render []
  (render
   [:div {}
    [:form {}
     [:fieldset {}
      
      ;; Title
      [:label {:for "title"} 
       [:div {:class "label-icon"} icons.title [:strong {} (i18n.text :title-field)]]]
      (input-template :title :title-placeholder :title-description)

      ;; Description
      [:label {:for "description"} 
       [:div {:class "label-icon"} icons.description [:strong {} (i18n.text :description-field)]]]
      (textarea-template :description :description-placeholder :description-description)
      
      ;; URL
      [:label {:for "url"} 
       [:div {:class "label-icon"} icons.url [:strong {} (i18n.text :url-field)]]]
      (input-template :url :url-placeholder :url-description)
      
      ;; QR-Code - Bild hochladen
      [:label {:for "qrcode"} 
       [:div {:class "label-icon"} icons.qrcode [:strong {} (i18n.text :qrcode-field)]]]
      [:div {}
       [:input {:id "qrcode"
                :type "file"
                :accept "image/*"
                :onchange read-qr-code}]
       [:small {} (i18n.text :qrcode-description)]]
      
      ;; Date and Time
      [:label {:for "datetime"} 
       [:div {:class "label-icon"} icons.calendar [:strong {} (i18n.text :datetime-field)]]]
      [:div {}
       [:input {:id "datetime"
                :rvid "datetime"
                :type "datetime-local"
                :oninput (fn [el] (app.render))}]
       [:small {} (i18n.text :datetime-description)]]
      
      ;; Files - mehrere Dateien hochladen
      [:label {:for "file-upload"} 
       [:div {:class "label-icon"} icons.files [:strong {} (i18n.text :files-field)]]]
      [:div {}
       [:input {:id "file-upload"
                :type "file"
                :multiple true
                :onchange update-files}]
       [:small {} (i18n.text :files-description)]
       (if (> (# state.files) 0)
           [:p {:class "wallet-file-list"}
            (table.concat
              (icollect [_ f (ipairs state.files)] f.name)
              " · ")])]
      
      ;; Preview
      (if (form-has-content?)
          [:article {}
           [:header {} (i18n.text :preview)]
           [:div {:class "wallet-card"}
            [:div {:class "wallet-header"}
             icons.wallet
             [:h3 {} (if (is-empty? :title) "Wallet Entry" RV.id.title.value)]]
            (if (not (is-empty? :description))
                [:p {:class "wallet-description"} 
                 icons.description
                 [:span {} RV.id.description.value]])
            (if (not (is-empty? :url))
                [:p {:class "wallet-url"} 
                 icons.url 
                 [:a {:href RV.id.url.value :target "_blank"} RV.id.url.value]])
            (if (not= state.qrcode-data nil)
                [:p {:class "wallet-qrcode"}
                 icons.qrcode
                 [:img {:src state.qrcode-data :alt "QR Code" :style "max-width: 150px; max-height: 150px;"}]])
            (if (not (is-empty? :datetime))
                [:p {:class "wallet-datetime"}
                 icons.calendar
                 [:span {} RV.id.datetime.value]])
            (if (> (# state.files) 0)
                [:p {:class "wallet-files"}
                 icons.attachment
                 [:span {} (table.concat
                             (icollect [_ f (ipairs state.files)] f.name)
                             " · ")]])]]
          [:article {:class "example"}
           [:header {} (i18n.text :preview)]
           [:p {:style "color: var(--pico-muted-color)"} "Wallet-Vorschau erscheint hier..."]])
      
      ;; Buttons
      [:div {:class "button-group"}
       [:input {:type "button" 
                :class "primary" 
                :disabled (if (form-has-content?) false true) 
                :value (i18n.text :send) 
                :onclick send-to-chat}]
       [:input {:type "button" 
                :class "outline" 
                :value (i18n.text :reset) 
                :onclick reset 
                :disabled (if (form-has-content?) false true)}]]]]
    ]"main"))

(app.render)

;; The footer is in here instead of index.fnl because we want the text to
;; change based on the language of the app.
(render [:div {} 
         (i18n.text :description)
         [:select {:name "select" :ariaLabel (i18n.text :select-language) :onchange i18n.setLang}
          [:option {:selected "" :value "" :disabled ""} (i18n.text :language)]
          [:option {:value "de"} "Deutsch"]
          [:option {:value "en"} "English"]]
         [:div {:id "version"}
          [:hr {}]
          [:p {} "Version 0.0.3"]
          [:hr {}]
          [:p {:class "license"} (i18n.text :anti-capitalist)]
          [:p {:class "license"} (i18n.text :open-source)]]] "#footer")
