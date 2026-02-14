(local i18n {})
(local js (require :js))
(local log (fn [...] (js.global.console:log ...)))

(set i18n.data 
     {
      ;; English
      :en {:description [:div {}
                         [:p {} [:b {} "Found ICE"] " is a tool to write down a possible ICE sighting using the SALUTE template (size, activity, location, uniform, time, equipment) and send it to those opposing ICE in the area."]
                         [:p {} "This tool is based on the template hosted on salute.kyr.digital."]]
           :select-language "Select language"
           :language "Language"
           :fuck-cops "Fuck Cops 🐖"
           :anti-capitalist "This is anti-capitalist software, released for free use by individuals and organizations that do not operate by capitalist principles."

           :size-placeholder "5 DHS cops"
           :size-description "How many agents/officers?"
           :activity-placeholder "standing outside of a donut shop"
           :activity-description "What are they doing?"
           :location-placeholder "43rd and Woodland"
           :location-description "What is the address or neighborhood?"
           :uniform-placeholder "DHS vests"
           :uniform-description "Letters and patches visible on jackets/vests/vehicles"
           :time-placeholder "13:12 PM"
           :time-description "When did you witness this?"
           :equipment-placeholder "guns and handcuffs"
           :equipment-description "What do they have with them?"
           }
      })

(fn lang-apply [lang dir]
  (let [html-el (js.global.document:querySelector "html")]
    (set i18n.locale lang)
    (html-el:setAttribute :lang lang)
    (html-el:setAttribute :dir dir)))

(fn i18n.setLang [el]
  (log "Changed language" el.value)
  (js.global.localStorage:setItem :lang el.value)
  (js.global.location:reload))

(fn i18n.text [key]
  (let [text (. i18n.data i18n.locale key)]
    ;; Return the text itself otherwise fallback to English
    (if (not= text nil)
        text
        (. i18n.data :en key))))

(let [saved (js.global.localStorage:getItem :lang)
      lang  (if (= saved js.null) :en saved)]
  (case lang
    :en    (lang-apply lang :ltr)))

i18n
