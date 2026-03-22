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
(local state {:files []})

;; This creates the header of the app
(render [:div {:class "container"}
         [:nav {}
          [:ul {}
           [:li {}
            [:div {:id "title"}
             icons.wallet
             [:b {} "💳 Delta Wallet"]]]]
          [:ul {}
           [:li {}
            [:div {:role "button"
                   :id "help"
                   :onclick (fn []
                              (log "Help clicked"))} "❓"]]]] "#nav")

;; Check if the input fields are filled or not.
(fn is-empty? [key]
  (or (= (?. RV.id key :value) nil) (= (?. RV.id key :value) "")))

;; Check if any required field is filled
(fn form-has-content? []
  (or (not (is-empty? :title))
      (not (is-empty? :description))
      (not (is-empty? :url))
      (not (is-empty? :qrcode))
      (not (is-empty? :datetime))))

;; Reset the form
(fn reset []
  (each [_ v (ipairs [:title :description :url :qrcode :datetime])]
    (if (not (is-empty? v))
        (set (. RV.id v :value) "")))
  (set state.files [])
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
  (let [obj (js.new js.global.Object)
        title (if (is-empty? :title) "Wallet Entry" RV.id.title.value)
        description (if (is-empty? :description) "" RV.id.description.value)
        url (if (is-empty? :url) "" RV.id.url.value)
        datetime (if (is-empty? :datetime) "" RV.id.datetime.value)]
    
    ;; Build a formatted message
    (set (. obj :text) (.. "💳 " title 
                           (if (= description "") "" (.. "\n\n" description))
                           (if (= url "") "" (.. "\n\n🔗 " url))
                           (if (= datetime "") "" (.. "\n\n📅 " datetime))))
    (webxdc:sendToChat obj)))

;; Render function for rendering the whole page
(fn app.render []
  (render
   [:div {}
    [:form {}
     [:fieldset {}
      
      ;; Title
      [:label {:for "title"} 
       [:div {:class "label-icon"} icons.wallet [:strong {} (i18n.text :title-field)]]]
      (input-template :title :title-placeholder :title-description)
      
           [:p {} "Version 0.0.1"]
      [:label {:for "description"} 
       [:div {:class "label-icon"} icons.description [:strong {} (i18n.text :description-field)]]]
      (textarea-template :description :description-placeholder :description-description)
      
      ;; URL
      [:label {:for "url"} 
       [:div {:class "label-icon"} icons.url [:strong {} (i18n.text :url-field)]]]
      (input-template :url :url-placeholder :url-description)
      
      ;; QR-Code
      [:label {:for "qrcode"} 
       [:div {:class "label-icon"} icons.qrcode [:strong {} (i18n.text :qrcode-field)]]]
      (input-template :qrcode :qrcode-placeholder :qrcode-description)
      
      ;; Date and Time
      [:label {:for "datetime"} 
       [:div {:class "label-icon"} icons.calendar [:strong {} (i18n.text :datetime-field)]]]
      (input-template :datetime :datetime-placeholder :datetime-description)
      
      ;; Files (placeholder for future file handling)
      [:label {} 
       [:div {:class "label-icon"} icons.files [:strong {} (i18n.text :files-field)]]]
      [:small {} (i18n.text :files-description)]
      [:small {:style "color: var(--pico-muted-color)"} "(Coming soon...)"]
      
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
            (if (not (is-empty? :qrcode))
                [:p {:class "wallet-qrcode"}
                 icons.qrcode
                 [:img {:src RV.id.qrcode.value :alt "QR Code" :style "max-width: 150px; max-height: 150px;"}]])
            (if (not (is-empty? :datetime))
                [:p {:class "wallet-datetime"}
                 icons.calendar
                 [:span {} RV.id.datetime.value]])]]
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
          [:p {} "Version 0.2.0"]
          [:hr {}]
          [:p {:class "license"} (i18n.text :anti-capitalist)]
          [:p {:class "license"} (i18n.text :open-source)]]] "#footer")
