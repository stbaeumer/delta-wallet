(local i18n {})
(local js (require :js))
(local log (fn [...] (js.global.console:log ...)))

(set i18n.data 
     {
      ;; English
      :en {:description [:div {}
                         [:p {} [:b {} "Found ICE"] " is a tool to write down a possible ICE sighting using the SALUTE template (size, activity, location, uniform, time, equipment) and send it to those opposing ICE in the area."]
                         [:p {} "This tool is based on the template hosted on "
                          [:a {:href "https://salute.kyr.digital"} "salute.kyr.digital"]]]
           :select-language "Select language"
           :language "Language"
           :fuck-cops "Fuck Cops 🐖"
           :anti-capitalist "This is anti-capitalist software, released for free use by individuals and organizations that do not operate by capitalist principles."

           :spotted "SPOTTED"
           
           :size "Size"
           :size-placeholder "5 DHS cops"
           :size-description "How many agents/officers?"

           :activity "Activity"
           :activity-placeholder "standing outside of a donut shop"
           :activity-description "What are they doing?"

           :location "Location"
           :location-placeholder "43rd and Woodland"
           :location-description "What is the address or neighborhood?"

           :uniform "Uniform"
           :uniform-placeholder "DHS vests"
           :uniform-description "Letters and patches visible on jackets/vests/vehicles"

           :time "Time"
           :time-placeholder "1:12 PM"
           :time-description "When did you witness this?"

           :equipment "Equipment"
           :equipment-placeholder "guns and handcuffs"
           :equipment-description "What do they have with them?"

           :with "with"
           :in "in"
           }
      ;; Spanish
      :es {:description [:div {}
                         [:p {} [:b {} "Found ICE"] " es una herramienta para anotar un posible avistamiento de ICE usando la plantilla SALUTE (tamaño, actividad, ubicación, uniforme, hora, equipo) y enviarla a quienes se oponen a ICE en la zona."]
                         [:p {} "Esta herramienta se basa en la plantilla alojada en " [:a {:href "https://salute.kyr.digital"} "salute.kyr.digital"]]]
           :select-language "Seleccionar idioma"
           :language "Idioma"
           :fuck-cops "¡Malditos malos policías! 🐖"
           :anti-capitalist "Este es un software anticapitalista, publicado para uso gratuito por personas y organizaciones que no operan según principios capitalistas."

           :spotted "Vi a"
           
           :size "Tamaño"
           :size-placeholder "5 agentes del DHS"
           :size-description "¿Cuántos agentes/oficiales?"

           :activity "Actividad"
           :activity-placeholder "De pie afuera de una tienda de donas"
           :activity-description "¿Qué están haciendo?"

           :location "Ubicación"
           :location-placeholder "43ª y Woodland"
           :location-description "¿Cuál es la dirección o el vecindario?"

           :uniform "Uniforme"
           :uniform-placeholder "Chalecos del DHS"
           :uniform-description "Letras y parches visibles en chaquetas/chalecos/vehículos"

           :time "Hora"
           :time-placeholder "1:12 PM"
           :time-description "¿Cuando fuiste testigo de esto?"

           :equipment "Equipo"
           :equipment-placeholder "armas y esposas"
           :equipment-description "¿Qué tienen consigo?"

           :with "y"
           :in "con"
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
    :en    (lang-apply lang :ltr)
    :es    (lang-apply lang :ltr)))

i18n
