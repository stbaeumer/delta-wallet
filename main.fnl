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
(local state {:feedback false})

;; This creates the header of the app
(render [:div {:class "container"}
         [:nav {}
          [:ul {}
           [:li {}
            [:div {:id "title"}
             icons.message
             [:b {} "Found ICE"]]]]
          [:ul {}
           [:li {}
            [:div {:role "button"
                   :id "donate"
                   :onclick (fn []
                              (set state.feedback true)
                              (app.render))} icons.coffee]]]]] "#nav")

;; Check if the input fields are filled or not.
(fn is-empty? [key]
  (or (= (?. RV.id key :value) nil) (= (?. RV.id key :value) "")))

;; Check if all the fields are empty.
(fn form-empty? []
  (and (is-empty? :size)
       (is-empty? :activity)
       (is-empty? :location)
       (is-empty? :uniform)
       (is-empty? :time)
       (is-empty? :equipment)))

;; Strip the current values in the form when the reset button is pressed
;; We run (is-empty?) first because RV.id.<key> might not exist yet.
(fn reset []
  (each [_ v (ipairs [:size :activity :location :uniform :time :equipment])]
    (if (not (is-empty? v))
        (set (. RV.id v :value) "")))
  (app.render))

(fn input-template [id]
  [:div {}
   [:input {:id id
            :rvid id
            :placeholder (i18n.text (.. id "-placeholder"))
            :oninput (fn [el] (app.render))}]
   [:small {} (i18n.text (.. id "-description"))]])

(fn send-to-chat []
  (let [obj (js.new js.global.Object)]
    (set (. obj :text) (.. "🚨 " (i18n.text :spotted) " @ "
                           (if (is-empty? :location)
                               ""
                               RV.id.location.value)
                           (if (is-empty? :time)
                               ""
                               (.. ", " RV.id.time.value))
                           (if (is-empty? :size)
                               ""
                               (.. " " RV.id.size.value))
                           (if (is-empty? :activity)
                               ""
                               (.. " " RV.id.activity.value))
                           (if (is-empty? :uniform)
                               ""
                               (.. " " (i18n.text :in) " " RV.id.uniform.value))
                           (if (is-empty? :equipment)
                               ""
                               (.. " " (i18n.text :with) " " RV.id.equipment.value))))
    (webxdc:sendToChat obj)))

;; Render function for rendering the whole page.
(fn app.render []
  (render
   [:div {}

    ;; Feedback
    (if state.feedback
        [:dialog {:open true}
         [:article {}
          [:header {}
           [:strong {} "Thanks for using!"]]
          [:p {}
           "You can leave feedback and download more tools on " [:a {:href "durianbean.itch.io"} "durianbean.itch.io"] " if you're interested."]
          [:p {} "Let me know what you think!"]
          [:button {:ariaLabel "close" :onclick (fn []
                                                  (set state.feedback false)
                                                  (app.render))} "Close"]]]
        [:dialog {:open false}])

    [:form {}

     [:fieldset {}
      ;; Size
      ;; ---------
      [:label {:for "size"} [:div {:class "label-icon"} icons.people [:strong {} (i18n.text :size)]]]
      (input-template :size)
      
      ;; Activity
      ;; ---------
      [:label {:for "activity"} [:div {:class "label-icon"} icons.donut [:strong {} (i18n.text :activity)]]]
      (input-template :activity)
      
      ;; Location
      ;; ---------
      [:label {:for "location"} [:div {:class "label-icon"} icons.location [:strong {} (i18n.text :location)]]]
      (input-template :location)
      
      ;; Uniform
      ;; ---------
      [:label {:for "uniform"} [:div {:class "label-icon"} icons.uniform [:strong {} (i18n.text :uniform)]]]
      (input-template :uniform)
      
      ;; Time
      ;; ---------
      [:label {:for "time"} [:div {:class "label-icon"} icons.time [:strong {} (i18n.text :time)]]]
      [:fieldset {:role "group"}
       [:input {:id "time"
                :rvid "time"
                :placeholder (i18n.text :time-placeholder)
                :oninput (fn [el] (app.render))}]
       [:input {:type "button"
                :value "Now"
                :onclick #(let [date (js.new js.global.Date)]
                            (set RV.id.time.value (date:toLocaleTimeString i18n.locale))
                            (app.render))}]]
      [:small {} (i18n.text :time-description)]

      ;; Equipment
      ;; ---------
      [:label {:for "equipment"} [:div {:class "label-icon"} icons.equipment [:strong {} (i18n.text :equipment)]]]
      (input-template :equipment)
      
     ;; Only display the example when all the inputs are empty
     (if (form-empty?)
         
         [:article {}
          [:header {} "Preview message"]
          
          [:div {:class "example"}
           [:p {} (.. "🚨 " (i18n.text :spotted) " @ "
                      (i18n.text :location-placeholder)
                      (.. ", " (i18n.text :time-placeholder)))]
           [:p {} (.. (i18n.text :size-placeholder)
                      (.. " " (i18n.text :activity-placeholder))
                      (.. " " (i18n.text :in) " " (i18n.text :uniform-placeholder))
                      (.. " " (i18n.text :with) " " (i18n.text :equipment-placeholder)))]]]
         
         [:article {}
          [:header {} "Message"]
          
          [:div {:class ""}
           [:p {} (.. "🚨 " (i18n.text :spotted) " @ "
                      (if (is-empty? :location)
                          ""
                          RV.id.location.value)
                      (if (is-empty? :time)
                          ""
                          (.. ", " RV.id.time.value)))]
           [:p {} (.. (if (is-empty? :size)
                          ""
                          RV.id.size.value)
                      (if (is-empty? :activity)
                          ""
                          (.. " " RV.id.activity.value))
                      (if (is-empty? :uniform)
                          ""
                          (.. " " (i18n.text :in) " " RV.id.uniform.value))
                      (if (is-empty? :equipment)
                          ""
                          (.. " " (i18n.text :with) " " RV.id.equipment.value)))]]])

      [:input {:type "button" :class "primary" :disabled (if (form-empty?) true false) :value "Send" :onclick send-to-chat}]
      [:input {:type "button" :class "outline" :value "Reset" :onclick reset :disabled (if (form-empty?) true false)}]]

    ]]"main"))

(app.render)

;; The footer is in here instead of index.fnl because we want the text to
;; change based on the language of the app. This shows the description of the app,
;; the license, and language switcher.
(render [:div {} 
         (i18n.text :description)
         [:select {:name "select" :ariaLabel (i18n.text :select-language) :onchange i18n.setLang}
          [:option {:selected "" :value "" :disabled ""} (i18n.text :language)]
          [:option {:value "en"} "English"]
          [:option {:value "es"} "Spanish"]]
         [:div {:id "version"}
          [:hr {}]
          [:p {} "Version 0.1.1c"]
          [:p {} (i18n.text :fuck-cops)]
          [:hr {}]
          [:p {:class "license"} (i18n.text :anti-capitalist)]
          [:p {:class "license"} "Anti-Capitalist Software License (v1.4)"]]] "#footer")
