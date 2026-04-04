#!/usr/bin/env python3
"""One-off: add DE/ES/FR/NL strings for the UI localization batch (keys already in app_en.arb)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N = ROOT / "lib" / "l10n"

# Keys that only need @ in en (already there) — no translation for @ entries in other locales
# (Flutter copies metadata from template; other locales omit @ if same structure — actually
# Flutter gen-l10n uses template for metadata. We only add message keys to de/es/fr/nl.)

T: dict[str, dict[str, str]] = {
    "commPrefChooseStyleTitle": {
        "de": "Wähle deinen Moody-Stil",
        "es": "Elige tu estilo de Moody",
        "fr": "Choisis ton style Moody",
        "nl": "Kies jouw Moody-stijl",
    },
    "commPrefChooseStyleSubtitle": {
        "de": "So passe ich meinen Ton perfekt an dich an.",
        "es": "Así adapto mi tono perfectamente a ti.",
        "fr": "Comme ça j’ajuste mon ton parfaitement à toi.",
        "nl": "Zo pas ik mijn toon perfect op jou aan.",
    },
    "commPrefSpeechBubble": {
        "de": "Wie soll ich mit dir sprechen? 😊",
        "es": "¿Cómo quieres que hable contigo? 😊",
        "fr": "Comment veux-tu que je te parle ? 😊",
        "nl": "Hoe wil je dat ik met je praat? 😊",
    },
    "authWelcomeTitle": {
        "de": "Du bist drin! Willkommen 🎉",
        "es": "¡Ya estás dentro! Bienvenido/a 🎉",
        "fr": "Tu es dedans ! Bienvenue 🎉",
        "nl": "Je bent erin! Welkom 🎉",
    },
    "authCallbackConfirmingEmail": {
        "de": "E-Mail wird bestätigt…",
        "es": "Confirmando tu correo…",
        "fr": "Confirmation de votre e-mail…",
        "nl": "Je e-mail wordt bevestigd…",
    },
    "authCallbackVerificationFailed": {
        "de": "E-Mail-Bestätigung fehlgeschlagen. Bitte versuche es erneut.",
        "es": "No se pudo verificar el correo. Inténtalo de nuevo.",
        "fr": "La vérification de l’e-mail a échoué. Réessaie.",
        "nl": "E-mailverificatie mislukt. Probeer het opnieuw.",
    },
    "dialogClose": {
        "de": "Schließen",
        "es": "Cerrar",
        "fr": "Fermer",
        "nl": "Sluiten",
    },
    "supportHowCanWeHelp": {
        "de": "Wobei können wir dir helfen?",
        "es": "¿En qué podemos ayudarte?",
        "fr": "Comment pouvons-nous t’aider ?",
        "nl": "Waarmee kunnen we je helpen?",
    },
    "supportContactUsCard": {
        "de": "Kontakt",
        "es": "Contáctanos",
        "fr": "Nous contacter",
        "nl": "Contact",
    },
    "supportSendFeedbackCard": {
        "de": "Feedback senden",
        "es": "Enviar comentarios",
        "fr": "Envoyer un avis",
        "nl": "Feedback sturen",
    },
    "supportTutorialCard": {
        "de": "Tutorial",
        "es": "Tutorial",
        "fr": "Tutoriel",
        "nl": "Tutorial",
    },
    "supportReportIssueCard": {
        "de": "Problem melden",
        "es": "Informar de un problema",
        "fr": "Signaler un problème",
        "nl": "Probleem melden",
    },
    "supportFaqSectionTitle": {
        "de": "Häufig gestellte Fragen",
        "es": "Preguntas frecuentes",
        "fr": "Questions fréquentes",
        "nl": "Veelgestelde vragen",
    },
    "supportFaq1Q": {
        "de": "Wie plane ich ein neues Abenteuer?",
        "es": "¿Cómo planifico una nueva aventura?",
        "fr": "Comment planifier une nouvelle aventure ?",
        "nl": "Hoe plan ik een nieuw avontuur?",
    },
    "supportFaq1A": {
        "de": "Geh zum Tab Entdecken und starte einen neuen Plan. Wähle Stimmung, Interessen und Reisevorlieben für personalisierte Vorschläge.",
        "es": "Ve a la pestaña Explorar y empieza un plan nuevo. Elige tu estado de ánimo, intereses y preferencias para recomendaciones personalizadas.",
        "fr": "Va dans l’onglet Explorer et lance un nouveau plan. Choisis ton humeur, tes intérêts et tes préférences pour des recommandations personnalisées.",
        "nl": "Ga naar het tabblad Ontdekken en start een nieuw plan. Kies je stemming, interesses en voorkeuren voor persoonlijke aanbevelingen.",
    },
    "supportFaq2Q": {
        "de": "Kann ich Orte für später speichern?",
        "es": "¿Puedo guardar sitios para más tarde?",
        "fr": "Puis-je enregistrer des lieux pour plus tard ?",
        "nl": "Kan ik plekken bewaren voor later?",
    },
    "supportFaq2A": {
        "de": "Ja! Tippe beim Ort auf das Herz, um ihn unter Gespeicherte Orte zu speichern — erreichbar über dein Profilmenü.",
        "es": "¡Sí! Toca el corazón en una ficha de lugar para guardarlo en Guardados, desde el menú de perfil.",
        "fr": "Oui ! Appuie sur le cœur sur une fiche lieu pour l’ajouter aux favoris, via le menu profil.",
        "nl": "Ja! Tik op het hart bij een plek om op te slaan onder Opgeslagen plekken via je profielmenu.",
    },
    "supportFaq3Q": {
        "de": "Wie tracke ich meine Stimmung?",
        "es": "¿Cómo registro mi estado de ánimo?",
        "fr": "Comment suivre mon humeur ?",
        "nl": "Hoe houd ik mijn stemming bij?",
    },
    "supportFaq3A": {
        "de": "WanderMood kann dich an Check-ins erinnern. Du kannst auch im Moody-Hub einen Eintrag hinzufügen.",
        "es": "WanderMood puede recordarte check-ins. También puedes añadir una entrada desde el hub de Moody.",
        "fr": "WanderMood peut te rappeler les check-ins. Tu peux aussi ajouter une entrée depuis le hub Moody.",
        "nl": "WanderMood kan je herinneren om in te checken. Je kunt ook een invoer toevoegen vanuit de Moody-hub.",
    },
    "supportFaq4Q": {
        "de": "Was bedeuten die Erfolgsabzeichen?",
        "es": "¿Qué significan las insignias de logros?",
        "fr": "Que signifient les badges de succès ?",
        "nl": "Wat betekenen de prestatiebadges?",
    },
    "supportFaq4A": {
        "de": "Abzeichen erhältst du für Aktivitäten in der App. Unter Erfolge im Profil siehst du die Anforderungen.",
        "es": "Ganas insignias por actividades en la app. En Logros del perfil verás los requisitos.",
        "fr": "Les badges récompensent des actions dans l’app. Va dans Succès du profil pour les conditions.",
        "nl": "Badges verdien je door activiteiten in de app. Bij Prestaties in je profiel zie je de vereisten.",
    },
    "supportFaq5Q": {
        "de": "Wie nutzt WanderMood meinen Standort?",
        "es": "¿Cómo usa WanderMood mi ubicación?",
        "fr": "Comment WanderMood utilise-t-il ma position ?",
        "nl": "Hoe gebruikt WanderMood mijn locatie?",
    },
    "supportFaq5A": {
        "de": "Für Vorschläge in deiner Nähe. Standortberechtigungen kannst du in den App-Einstellungen anpassen.",
        "es": "Para sugerir sitios cercanos. Puedes ajustar los permisos de ubicación en ajustes.",
        "fr": "Pour proposer des lieux à proximité. Tu peux ajuster les autorisations dans les réglages.",
        "nl": "Voor suggesties in de buurt. Locatiemachtigingen pas je aan in de app-instellingen.",
    },
    "supportFaq6Q": {
        "de": "Kann ich WanderMood offline nutzen?",
        "es": "¿Puedo usar WanderMood sin conexión?",
        "fr": "Puis-je utiliser WanderMood hors ligne ?",
        "nl": "Kan ik WanderMood offline gebruiken?",
    },
    "supportFaq6A": {
        "de": "Einige Funktionen brauchen Internet. Gespeicherte Inhalte sind oft weiterhin sichtbar.",
        "es": "Algunas funciones requieren internet. Lo guardado a veces sigue visible.",
        "fr": "Certaines fonctions nécessitent Internet. Le contenu enregistré peut rester visible.",
        "nl": "Sommige functies hebben internet nodig. Opgeslagen items zijn vaak nog te zien.",
    },
    "supportAdditionalResources": {
        "de": "Weitere Ressourcen",
        "es": "Recursos adicionales",
        "fr": "Ressources supplémentaires",
        "nl": "Extra bronnen",
    },
    "supportAppVersionLabel": {
        "de": "App-Version",
        "es": "Versión de la app",
        "fr": "Version de l’appli",
        "nl": "App-versie",
    },
    "supportContactDialogTitle": {
        "de": "Support kontaktieren",
        "es": "Contactar soporte",
        "fr": "Contacter le support",
        "nl": "Contact opnemen",
    },
    "supportEmailUsAt": {
        "de": "Schreib uns an:",
        "es": "Escríbenos a:",
        "fr": "Écris-nous à :",
        "nl": "Mail ons op:",
    },
    "supportEmailSupportHours": {
        "de": "Unser Support ist Montag–Freitag, 9–17 Uhr PST erreichbar.",
        "es": "Nuestro equipo está disponible de lunes a viernes, 9–17 h PST.",
        "fr": "Notre équipe est disponible du lundi au vendredi, 9h–17h PST.",
        "nl": "Ons team is bereikbaar ma–vr, 9:00–17:00 PST.",
    },
    "supportToastOpeningFeedback": {
        "de": "Feedback wird geöffnet…",
        "es": "Abriendo formulario de comentarios…",
        "fr": "Ouverture du formulaire d’avis…",
        "nl": "Feedbackformulier openen…",
    },
    "supportToastOpeningTutorial": {
        "de": "Tutorial wird geöffnet…",
        "es": "Abriendo tutorial…",
        "fr": "Ouverture du tutoriel…",
        "nl": "Tutorial openen…",
    },
    "supportToastOpeningIssue": {
        "de": "Meldung wird geöffnet…",
        "es": "Abriendo informe de incidencia…",
        "fr": "Ouverture du rapport…",
        "nl": "Melding openen…",
    },
    "recListTitle": {
        "de": "Reiseempfehlungen",
        "es": "Recomendaciones de viaje",
        "fr": "Recommandations de voyage",
        "nl": "Reisaanbevelingen",
    },
    "recErrorPrefix": {
        "de": "Fehler:",
        "es": "Error:",
        "fr": "Erreur :",
        "nl": "Fout:",
    },
    "recTryAgain": {
        "de": "Erneut versuchen",
        "es": "Reintentar",
        "fr": "Réessayer",
        "nl": "Opnieuw proberen",
    },
    "recNoneAvailable": {
        "de": "Keine Empfehlungen verfügbar",
        "es": "No hay recomendaciones",
        "fr": "Aucune recommandation",
        "nl": "Geen aanbevelingen beschikbaar",
    },
    "recLocationLabel": {
        "de": "Ort: {location}",
        "es": "Ubicación: {location}",
        "fr": "Lieu : {location}",
        "nl": "Locatie: {location}",
    },
    "recPriceLabel": {
        "de": "Preis: {price}",
        "es": "Precio: {price}",
        "fr": "Prix : {price}",
        "nl": "Prijs: {price}",
    },
    "recFavoriteUpdated": {
        "de": "Favorit aktualisiert",
        "es": "Favorito actualizado",
        "fr": "Favori mis à jour",
        "nl": "Favoriet bijgewerkt",
    },
    "recFavoriteError": {
        "de": "Favorit konnte nicht aktualisiert werden: {error}",
        "es": "Error al actualizar favorito: {error}",
        "fr": "Erreur lors de la mise à jour du favori : {error}",
        "nl": "Favoriet bijwerken mislukt: {error}",
    },
    "recDetailTitle": {
        "de": "Empfehlungsdetails",
        "es": "Detalles de la recomendación",
        "fr": "Détails de la recommandation",
        "nl": "Aanbevelingdetails",
    },
    "recDetailMarkCompleteTooltip": {
        "de": "Als erledigt markieren",
        "es": "Marcar como completado",
        "fr": "Marquer comme terminé",
        "nl": "Markeren als voltooid",
    },
    "recDetailStatusCompleted": {
        "de": "Erledigt",
        "es": "Completado",
        "fr": "Terminé",
        "nl": "Voltooid",
    },
    "recDetailStatusNotCompleted": {
        "de": "Noch nicht erledigt",
        "es": "Aún no completado",
        "fr": "Pas encore terminé",
        "nl": "Nog niet voltooid",
    },
    "recDetailSectionDescription": {
        "de": "Beschreibung",
        "es": "Descripción",
        "fr": "Description",
        "nl": "Beschrijving",
    },
    "recDetailSectionCategory": {
        "de": "Kategorie",
        "es": "Categoría",
        "fr": "Catégorie",
        "nl": "Categorie",
    },
    "recDetailSectionTags": {
        "de": "Tags",
        "es": "Etiquetas",
        "fr": "Tags",
        "nl": "Tags",
    },
    "recDetailSectionConfidence": {
        "de": "Zuverlässigkeit",
        "es": "Confianza",
        "fr": "Confiance",
        "nl": "Betrouwbaarheid",
    },
    "recDetailSectionMood": {
        "de": "Stimmung",
        "es": "Estado de ánimo",
        "fr": "Humeur",
        "nl": "Stemming",
    },
    "recDetailMoodRegisteredOn": {
        "de": "Erfasst am {date}",
        "es": "Registrado el {date}",
        "fr": "Enregistré le {date}",
        "nl": "Geregistreerd op {date}",
    },
    "recDetailSectionWeather": {
        "de": "Wetter",
        "es": "Tiempo",
        "fr": "Météo",
        "nl": "Weer",
    },
    "recDetailWeatherSubtitle": {
        "de": "{temp}°C, {humidity} % Luftfeuchtigkeit",
        "es": "{temp}°C, {humidity} % de humedad",
        "fr": "{temp}°C, {humidity} % d’humidité",
        "nl": "{temp}°C, {humidity}% luchtvochtigheid",
    },
    "adventurePlanTitleYour": {
        "de": "Dein ",
        "es": "Tu ",
        "fr": "Ton ",
        "nl": "Jouw ",
    },
    "adventurePlanTitleHighlight": {
        "de": "Abenteuerplan",
        "es": "plan de aventura",
        "fr": "plan d’aventure",
        "nl": "avonturenplan",
    },
    "adventurePlanTitleForToday": {
        "de": " für heute",
        "es": " de hoy",
        "fr": " pour aujourd’hui",
        "nl": " voor vandaag",
    },
    "adventurePlanLoadError": {
        "de": "Fehler beim Laden der Abenteuer: {error}",
        "es": "Error al cargar aventuras: {error}",
        "fr": "Erreur de chargement des aventures : {error}",
        "nl": "Fout bij laden van avonturen: {error}",
    },
    "receiptDownloadPdf": {
        "de": "PDF herunterladen",
        "es": "Descargar PDF",
        "fr": "Télécharger le PDF",
        "nl": "PDF downloaden",
    },
    "receiptShare": {
        "de": "Beleg teilen",
        "es": "Compartir recibo",
        "fr": "Partager le reçu",
        "nl": "Bon delen",
    },
    "placePhotoTapToView": {
        "de": "Tippen zum Anzeigen",
        "es": "Toca para ver",
        "fr": "Appuyer pour voir",
        "nl": "Tik om te bekijken",
    },
    "periodActivitiesRemoveTitle": {
        "de": "Aktivität entfernen?",
        "es": "¿Quitar actividad?",
        "fr": "Retirer l’activité ?",
        "nl": "Activiteit verwijderen?",
    },
    "periodActivitiesRemoveBody": {
        "de": "Möchtest du „{name}“ wirklich entfernen?",
        "es": "¿Seguro que quieres quitar \"{name}\"?",
        "fr": "Retirer « {name} » ?",
        "nl": "Weet je zeker dat je \"{name}\" wilt verwijderen?",
    },
    "periodActivitiesRemoveCta": {
        "de": "Entfernen",
        "es": "Quitar",
        "fr": "Retirer",
        "nl": "Verwijderen",
    },
    "periodActivitiesSwipeDelete": {
        "de": "Löschen",
        "es": "Eliminar",
        "fr": "Supprimer",
        "nl": "Verwijderen",
    },
    "periodActivitiesSwipeComplete": {
        "de": "Erledigt",
        "es": "Completar",
        "fr": "Terminer",
        "nl": "Voltooien",
    },
    "weatherFailedLoadCurrent": {
        "de": "Wetter konnte nicht geladen werden",
        "es": "No se pudo cargar el tiempo",
        "fr": "Impossible de charger la météo",
        "nl": "Kon het weer niet laden",
    },
    "weatherFailedLoadForecast": {
        "de": "Vorhersage konnte nicht geladen werden",
        "es": "No se pudo cargar el pronóstico",
        "fr": "Impossible de charger les prévisions",
        "nl": "Kon de voorspelling niet laden",
    },
    "weatherNoDataAvailable": {
        "de": "Keine Wetterdaten verfügbar",
        "es": "No hay datos meteorológicos",
        "fr": "Aucune donnée météo",
        "nl": "Geen weergegevens beschikbaar",
    },
    "weatherShowMore": {
        "de": "Mehr anzeigen",
        "es": "Ver más",
        "fr": "Voir plus",
        "nl": "Meer weergeven",
    },
    "weatherShowLess": {
        "de": "Weniger anzeigen",
        "es": "Ver menos",
        "fr": "Voir moins",
        "nl": "Minder weergeven",
    },
    "locationPickerSelectTitle": {
        "de": "Standort wählen",
        "es": "Elegir ubicación",
        "fr": "Choisir un lieu",
        "nl": "Locatie kiezen",
    },
    "weatherLoadError": {
        "de": "Fehler beim Laden der Wetterdaten: {error}",
        "es": "Error al cargar el tiempo: {error}",
        "fr": "Erreur de chargement météo : {error}",
        "nl": "Fout bij laden van weergegevens: {error}",
    },
    "weatherStatsTitle": {
        "de": "Wetterstatistik",
        "es": "Estadísticas del tiempo",
        "fr": "Statistiques météo",
        "nl": "Weerstatistieken",
    },
    "weatherHistoryTitle": {
        "de": "Wetterverlauf",
        "es": "Historial del tiempo",
        "fr": "Historique météo",
        "nl": "Weergeschiedenis",
    },
    "weatherToggleTemperature": {
        "de": "Temperatur",
        "es": "Temperatura",
        "fr": "Température",
        "nl": "Temperatuur",
    },
    "weatherToggleHumidity": {
        "de": "Luftfeuchtigkeit",
        "es": "Humedad",
        "fr": "Humidité",
        "nl": "Vochtigheid",
    },
    "weatherTogglePrecipitation": {
        "de": "Niederschlag",
        "es": "Precipitación",
        "fr": "Précipitations",
        "nl": "Neerslag",
    },
    "weatherForecastTitle": {
        "de": "Vorhersage",
        "es": "Pronóstico",
        "fr": "Prévisions",
        "nl": "Voorspelling",
    },
    "weatherNoForecasts": {
        "de": "Keine Vorhersagen verfügbar",
        "es": "No hay pronósticos",
        "fr": "Aucune prévision",
        "nl": "Geen voorspellingen beschikbaar",
    },
    "weatherAlertsTitle": {
        "de": "Wetterwarnungen",
        "es": "Alertas meteorológicas",
        "fr": "Alertes météo",
        "nl": "Weerwaarschuwingen",
    },
    "weatherNoActiveAlerts": {
        "de": "Keine aktiven Warnungen",
        "es": "No hay alertas activas",
        "fr": "Aucune alerte active",
        "nl": "Geen actieve waarschuwingen",
    },
    "weatherHistoryEmpty": {
        "de": "Keine historischen Daten verfügbar",
        "es": "No hay datos históricos",
        "fr": "Aucune donnée historique",
        "nl": "Geen historische gegevens beschikbaar",
    },
    "weatherHistoryInvalid": {
        "de": "Keine gültigen historischen Daten",
        "es": "No hay datos históricos válidos",
        "fr": "Aucune donnée historique valide",
        "nl": "Geen geldige historische gegevens",
    },
    "moodHistoryEmpty": {
        "de": "Keine Stimmungsverlaufsdaten",
        "es": "No hay historial de estado de ánimo",
        "fr": "Aucun historique d’humeur",
        "nl": "Geen stemminggeschiedenis beschikbaar",
    },
}


def main() -> None:
    en_path = L10N / "app_en.arb"
    en_data = json.loads(en_path.read_text(encoding="utf-8"))
    for key in T:
        if key not in en_data:
            raise SystemExit(f"Key {key} missing from app_en.arb")

    for code in ("de", "es", "fr", "nl"):
        path = L10N / f"app_{code}.arb"
        data = json.loads(path.read_text(encoding="utf-8"))
        for key, langs in T.items():
            data[key] = langs[code]
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(path.name, len(T), "keys")

    print("Done.")


if __name__ == "__main__":
    main()
