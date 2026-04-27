#!/usr/bin/env python3
"""Bootstrap: merge moody place-thread opener keys into lib/l10n/app_*.arb.

Source of truth after the first merge is the ARB files (and
lib/features/home/presentation/utils/moody_place_thread_opener_l10n.dart).
Re-run only if you reset ARBs; the script skips when keys already exist.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

STYLES = ["Friendly", "Professional", "Direct", "Energetic"]

# --- Locale bundles: explore[style] = 6 strings with {place}; myday[style] = 6 (empty, place) ---

LOCALES: dict[str, dict] = {
    "en": {
        "fallback": "this spot",
        "explore": {
            "Friendly": [
                "Ooh—{place}. I'm here with you. Crowd, light, best time… what do you want to know?",
                "{place}… nice. Where are you stuck—timing, vibe, or a backup nearby?",
                "Ok I'm zoomed in on {place}. No brochure voice—just ask.",
                "If you're stress-testing {place}: what do you need right now—quiet, energy, plan B?",
                "{place}'s pinned. What do you want to know before you drop it in your day?",
                'Say the awkward part about {place}—kid chaos? date night? "is this dumb right now?" All fine.',
            ],
            "Professional": [
                "Let's look at {place}. What do you need: crowds, lighting, or the best time to go?",
                "For {place}, what's unclear—schedule, atmosphere, or a nearby alternative?",
                "Focus: {place}. Ask your question—I'll answer plainly, without brochure language.",
                "About {place}: do you need calm, energy, or a backup option?",
                "{place} is set. What information do you need before you add it to your day?",
                "Ask about {place}—fit, timing, or practical concerns.",
            ],
            "Direct": [
                "{place}—crowds, light, best time. What?",
                "{place}. Timing, vibe, backup?",
                "{place}. Your question?",
                "{place}. Quiet, energy, or plan B?",
                "{place}. What do you need to know?",
                "{place}—say what you're checking.",
            ],
            "Energetic": [
                "Ooh—{place}! Hit me: crowds, light, best time… what do you want to know? ✨",
                "{place}… love it. Where are you stuck—time, vibe, plan B? 🔥",
                "Locked on {place}—no brochure voice, just ask 💬",
                "Stress-testing {place}: quiet, energy, or backup nearby? ⚡",
                "{place}'s pinned—what do you want to know before you drop it in your day? 🙌",
                "Say the awkward part about {place}—all good 😅",
            ],
        },
        "myday": {
            "Friendly": [
                ('This free slice—what do you want sharp on: swap, timing, or "does this even fit"?', "That {place} block—say what's bugging you: swap, timing, vibe…"),
                ("I'm watching this empty slot with you. What would you *want* to feel today?", "{place} on your day—tweak it or trade it?"),
                ("Free time. No question is too small.", "About {place}—real talk: are you unsure it fits today?"),
                ("Let's keep this slot human: what's the actual question?", "{place}… backup, better timing, or just certainty?"),
                ("I'm here. What do you want to know about this part of your day?", "I'm on {place}. What part of the plan is giving you friction?"),
                ("Go—I'll add context, you steer the vibe.", "{place}: say what you need. I'll match it."),
            ],
            "Professional": [
                ("This open block: swap, timing, or does it fit your plan?", "Your {place} block: what do you need—swap, timing, or atmosphere?"),
                ("Empty slot: what do you want to achieve today?", "{place} on your schedule: adjust or replace?"),
                ("Free time. What question matters most?", "About {place}: does it fit today's plan?"),
                ("This time window: what's the core question?", "{place}: backup, better timing, or certainty?"),
                ("How can I help with this part of your day?", "For {place}: where is your plan sticking?"),
                ("Ask your question; I'll help with context.", "{place}: what do you need?"),
            ],
            "Direct": [
                ("Open block. Swap, timing, fit?", "{place} block. Swap, timing, vibe?"),
                ("Empty slot. What feeling?", "{place}. Tweak or trade?"),
                ("Free. Question?", "{place}. Fits today?"),
                ("Slot. Real question?", "{place}. Backup, timing, certainty?"),
                ("This slice. What?", "{place}. Friction?"),
                ("Go.", "{place}. What?"),
            ],
            "Energetic": [
                ('Free slice—sharp on: swap, timing, or "does this even fit"? ⚡', "That {place} block—say what's bugging you: swap, timing, vibe ✨"),
                ("Empty slot—what do you *want* to feel today? 🔥", "{place} on your day—tweak it or trade it? 💬"),
                ("Free time. No question is too small 🙌", "About {place}—real talk: unsure it fits today? 😅"),
                ("Keep this slot human: what's the actual question? ✨", "{place}… backup, better timing, or certainty? ⚡"),
                ("I'm here—what do you want to know about this part of your day? 💬", "I'm on {place}—where's the friction in your plan? 🔥"),
                ("Go—I'll add context, you steer the vibe 🙌", "{place}: say what you need. I'll match it ✨"),
            ],
        },
    },
    "nl": {
        "fallback": "deze plek",
        "explore": {
            "Friendly": [
                "Oeh — {place}. Ik zit erbij. Schiet: drukte, licht, beste moment… wat wil je weten?",
                "{place}… nice. Waar twijfel je — tijd, sfeer, of een plan B dichtbij?",
                "Oké, ik focus op {place}. Geen folder-tekst — gewoon je vraag.",
                "Als je {place} wilt uitspitten: wat heb je nú nodig — rust, energie, of iets anders in de buurt?",
                "{place} staat vast. Ik lees mee — wat wil je weten voordat je 'm in je dag smijt?",
                'Zeg het hardop over {place} — kindproof? date? "ben ik hier dom aan begonnen?" Mag allemaal.',
            ],
            "Professional": [
                "We bespreken {place}. Wat wil je weten: drukte, licht of het beste moment?",
                "{place}: waar zit je vast — planning, sfeer of een alternatief dichtbij?",
                "Focus op {place}. Stel je vraag; ik antwoord informatief, zonder marketingtaal.",
                "Voor {place}: heb je rust, energie of een plan B nodig?",
                "{place} staat klaar. Welke informatie wil je vóór je het plant?",
                "Stel je vraag over {place} — geschiktheid, timing of praktische twijfels.",
            ],
            "Direct": [
                "{place} — drukte, licht, beste moment. Wat?",
                "{place}. Timing, sfeer, backup?",
                "{place}. Wat is je vraag?",
                "{place}. Rust, energie of plan B?",
                "{place}. Wat moet je weten?",
                "{place} — zeg wat je wilt checken.",
            ],
            "Energetic": [
                "Oeh — {place}! Schiet maar: drukte, licht, beste moment… wat wil je weten? ✨",
                "{place}… nice! Waar twijfel je — tijd, vibe, plan B? 🔥",
                "Locked op {place} — geen folder-praat, vuur je vraag af 💬",
                "Stress-test {place}: rust, energie of plan B in de buurt? ⚡",
                "{place} staat vast — wat wil je weten vóór je 'm in je dag smijt? 🙌",
                "Spui je awkward truth over {place} — alles mag 😅",
            ],
        },
        "myday": {
            "Friendly": [
                ('Dit stukje vrije tijd — waar wil je scherp op: alternatief, timing, of gewoon "klopt dit"?', "Je blok rond {place} — zeg wat je wringt: alternatief, timing, sfeer…"),
                ("Ik kijk mee met je lege slot. Wat zou je vandaag wél willen voelen?", "{place} in je schema — wil je het schaven of ruilen?"),
                ("Vrij moment. Geen stress-vraag is te klein.", "Over {place}: eerlijk — twijfel je of dit slim past vandaag?"),
                ("Laten we dit slot normaal houden: wat is je echte vraag?", "{place}… vertel: backup, beter moment, of gewoon zekerheid?"),
                ("Ik ben er. Wat wil je weten over dit stuk van je dag?", "Ik zit op {place}. Waar krijg je hoofdpijn van in je planning?"),
                ("Schiet — ik fix context, jij fix je vibe.", "{place}: zeg wat je nodig hebt. Ik werk mee."),
            ],
            "Professional": [
                ("Dit vrije blok: alternatief, timing of past het in je planning?", "Je blok rond {place}: wat wil je weten—alternatief, timing of sfeer?"),
                ("Leeg slot: wat wil je vandaag bereiken?", "{place} in je schema: bijwerken of ruilen?"),
                ("Vrije tijd. Welke vraag is het meest relevant?", "Over {place}: past dit vandaag in je plan?"),
                ("Dit tijdslot: wat is je kernvraag?", "{place}: backup, beter moment of zekerheid?"),
                ("Waar kan ik je mee helpen bij dit deel van je dag?", "Over {place}: waar wringt je planning?"),
                ("Stel je vraag; ik help met context.", "{place}: wat heb je nodig?"),
            ],
            "Direct": [
                ("Vrij blok. Alternatief, timing, klopt het?", "{place}-blok. Alternatief, timing, sfeer?"),
                ("Leeg slot. Wat wil je voelen?", "{place}. Schaven of ruilen?"),
                ("Vrij. Vraag?", "{place}. Past vandaag?"),
                ("Slot. Echte vraag?", "{place}. Backup, moment, zekerheid?"),
                ("Dit stuk. Wat?", "{place}. Frictie?"),
                ("Schiet.", "{place}. Wat?"),
            ],
            "Energetic": [
                ('Vrij stukje — scherp: alternatief, timing of "klopt dit"? ⚡', "Blok rond {place} — zeg wat wringt: alternatief, timing, vibe ✨"),
                ("Leeg slot — wat wil je vandaag wél voelen? 🔥", "{place} in je schema — schaven of ruilen? 💬"),
                ("Vrij moment — geen vraag is te klein 🙌", "Over {place} — twijfel je of dit slim past vandaag? 😅"),
                ("Houd dit slot menselijk: wat is je echte vraag? ✨", "{place} — backup, beter moment, zekerheid? ⚡"),
                ("Ik ben er — wat wil je weten over dit stuk van je dag? 💬", "Ik zit op {place} — waar knelt je planning? 🔥"),
                ("Schiet — ik fix context, jij je vibe 🙌", "{place} — zeg wat je nodig hebt, ik werk mee ✨"),
            ],
        },
    },
    "de": {
        "fallback": "dieser Ort",
        "explore": {
            "Friendly": [
                "Ooh—{place}. Ich bin dabei. Andrang, Licht, beste Zeit… was willst du wissen?",
                "{place}… schön. Wo hakt’s—Zeit, Stimmung oder Plan B in der Nähe?",
                "Ok, ich zoom auf {place}. Kein Prospekt-Ton—frag einfach.",
                "Wenn du {place} checkst: was brauchst du jetzt—Ruhe, Energie, Plan B?",
                "{place} ist drin. Was willst du wissen, bevor du’s in den Tag legst?",
                "Sag’s offen zu {place}—kindtauglich? Date? „Bin ich blöd unterwegs?“ Alles okay.",
            ],
            "Professional": [
                "Zu {place}: Was brauchst du—Andrang, Licht oder die beste Zeit?",
                "{place}: Was ist unklar—Zeitplan, Atmosphäre oder eine Alternative in der Nähe?",
                "Fokus auf {place}. Stell deine Frage—ich antworte sachlich, ohne Broschürenton.",
                "Zu {place}: brauchst du Ruhe, Energie oder Plan B?",
                "{place} steht. Welche Infos brauchst du, bevor du es einplanst?",
                "Frag zu {place}—Passt es, Timing oder praktische Zweifel?",
            ],
            "Direct": [
                "{place}—Andrang, Licht, beste Zeit. Was?",
                "{place}. Zeit, Stimmung, Plan B?",
                "{place}. Deine Frage?",
                "{place}. Ruhe, Energie oder Plan B?",
                "{place}. Was musst du wissen?",
                "{place}—sag, was du prüfen willst.",
            ],
            "Energetic": [
                "Ooh—{place}! Schieß los: Andrang, Licht, beste Zeit… was willst du wissen? ✨",
                "{place}… nice! Wo hakt’s—Zeit, Vibe, Plan B? 🔥",
                "Fokus auf {place}—kein Prospekt-Ton, frag einfach 💬",
                "{place} stress-testen: ruhig, Energie oder Plan B in der Nähe? ⚡",
                "{place} ist drin—was willst du wissen, bevor du’s in den Tag packst? 🙌",
                "Sag das Unbequeme zu {place}—alles gut 😅",
            ],
        },
        "myday": {
            "Friendly": [
                ('Freies Stück—worauf willst du’s schärfen: Tausch, Timing oder „passt das überhaupt“?', "Block um {place}—was nervt: Tausch, Timing, Stimmung…"),
                ("Ich schau mit auf dein leeres Fenster. Was willst du heute *wirklich* fühlen?", "{place} im Tag—anpassen oder tauschen?"),
                ("Freie Zeit. Keine Frage ist zu klein.", "Zu {place}—ehrlich: unsicher, ob’s heute passt?"),
                ("Bleib menschlich: was ist die echte Frage?", "{place}… Plan B, besserer Zeitpunkt oder Klarheit?"),
                ("Ich bin da. Was willst du über diesen Teil deines Tages wissen?", "Ich bin bei {place}. Wo klemmt der Plan?"),
                ("Los—ich liefere Kontext, du die Stimmung.", "{place}: sag, was du brauchst. Ich passe mich an."),
            ],
            "Professional": [
                ("Offener Block: Tausch, Timing oder passt es in den Plan?", "Dein Block zu {place}: was brauchst du—Tausch, Timing oder Atmosphäre?"),
                ("Leeres Fenster: was willst du heute erreichen?", "{place} im Kalender: anpassen oder ersetzen?"),
                ("Freie Zeit. Welche Frage ist am wichtigsten?", "Zu {place}: passt es zum heutigen Plan?"),
                ("Dieses Zeitfenster: was ist die Kernfrage?", "{place}: Plan B, besserer Zeitpunkt oder Sicherheit?"),
                ("Wobei kann ich bei diesem Tagesabschnitt helfen?", "Zu {place}: wo hakt deine Planung?"),
                ("Stell deine Frage; ich helfe mit Kontext.", "{place}: was brauchst du?"),
            ],
            "Direct": [
                ("Offener Block. Tausch, Timing, passt?", "{place}-Block. Tausch, Timing, Stimmung?"),
                ("Leer. Welches Gefühl?", "{place}. Anpassen oder tauschen?"),
                ("Frei. Frage?", "{place}. Passt heute?"),
                ("Slot. Echte Frage?", "{place}. Plan B, Timing, Klarheit?"),
                ("Dieses Stück. Was?", "{place}. Reibung?"),
                ("Los.", "{place}. Was?"),
            ],
            "Energetic": [
                ('Frei—scharf: Tausch, Timing oder „passt das“? ⚡', "Block um {place}—was nervt: Tausch, Timing, Vibe ✨"),
                ("Leer—was willst du heute *fühlen*? 🔥", "{place} im Tag—tunen oder tauschen? 💬"),
                ("Freie Zeit. Keine Frage zu klein 🙌", "Zu {place}—ehrlich: unsicher, ob’s heute passt? 😅"),
                ("Bleib fair: was ist die echte Frage? ✨", "{place}… Plan B, Timing, Klarheit? ⚡"),
                ("Ich bin da—was willst du über diesen Tagteil wissen? 💬", "Ich bin bei {place}—wo knirscht der Plan? 🔥"),
                ("Los—Kontext von mir, Vibe von dir 🙌", "{place}: sag, was du brauchst. Ich match’s ✨"),
            ],
        },
    },
    "fr": {
        "fallback": "ce lieu",
        "explore": {
            "Friendly": [
                "Ooh—{place}. Je suis avec toi. Affluence, lumière, meilleur moment… tu veux savoir quoi ?",
                "{place}… sympa. Tu bloques où—horaire, ambiance, ou plan B à côté ?",
                "Ok, je zoome sur {place}. Pas de ton brochure—pose ta question.",
                "Si tu testes {place} : tu as besoin de quoi—calme, énergie, plan B ?",
                "{place} est noté. Tu veux savoir quoi avant de l’ajouter à ta journée ?",
                "Dis la partie gênante sur {place}—kids, date, « c’est débile ? » Tout va bien.",
            ],
            "Professional": [
                "Parlons de {place}. Tu veux quoi : affluence, lumière, ou le meilleur moment ?",
                "Pour {place}, qu’est-ce qui bloque—horaire, ambiance, ou une option à côté ?",
                "Focus sur {place}. Pose ta question—je réponds clairement, sans langage promo.",
                "Pour {place} : tu as besoin de calme, d’énergie, ou d’un plan B ?",
                "{place} est prêt. Quelle info te manque avant de l’ajouter à ta journée ?",
                "Une question sur {place}—adéquation, timing, ou détails pratiques ?",
            ],
            "Direct": [
                "{place}—affluence, lumière, meilleur moment. Quoi ?",
                "{place}. Horaire, ambiance, plan B ?",
                "{place}. Ta question ?",
                "{place}. Calme, énergie ou plan B ?",
                "{place}. Tu dois savoir quoi ?",
                "{place}—dis ce que tu vérifies.",
            ],
            "Energetic": [
                "Ooh—{place}! Vas-y : affluence, lumière, meilleur moment… tu veux savoir quoi ? ✨",
                "{place}… j’adore. Tu bloques où—temps, vibe, plan B ? 🔥",
                "Verrouillé sur {place}—pas de brochure, demande 💬",
                "Test {place} : calme, énergie ou plan B à côté ? ⚡",
                "{place} est épinglé—tu veux savoir quoi avant de le mettre dans ta journée ? 🙌",
                "Dis la partie relou sur {place}—tout bon 😅",
            ],
        },
        "myday": {
            "Friendly": [
                ('Ce créneau libre—tu veux quoi de précis : swap, timing, ou « ça colle ou pas » ?', "Le bloc {place}—ce qui coince : swap, timing, ambiance…"),
                ("Je regarde le trou avec toi. Tu voudrais *vraiment* ressentir quoi aujourd’hui ?", "{place} dans ta journée—tu l’ajustes ou tu l’échanges ?"),
                ("Temps libre. Aucune question n’est trop petite.", "Pour {place}—franchement : tu doutes que ça colle aujourd’hui ?"),
                ("Restons humains : c’est quoi la vraie question ?", "{place}… plan B, meilleur moment, ou juste être sûr·e ?"),
                ("Je suis là. Tu veux savoir quoi sur cette partie de ta journée ?", "Je suis sur {place}. Qu’est-ce qui bloque dans ton planning ?"),
                ("Go—je donne le contexte, tu pilotes l’ambiance.", "{place}: dis ce dont tu as besoin. Je m’aligne."),
            ],
            "Professional": [
                ("Ce bloc libre : échange, timing, ou ça rentre dans le plan ?", "Ton bloc {place} : tu as besoin de quoi—échange, timing ou ambiance ?"),
                ("Créneau vide : tu veux accomplir quoi aujourd’hui ?", "{place} sur l’agenda : ajuster ou remplacer ?"),
                ("Temps libre. Quelle question est la plus importante ?", "Pour {place} : est-ce que ça correspond au plan du jour ?"),
                ("Cette fenêtre : quelle est la question centrale ?", "{place} : plan B, meilleur moment, ou certitude ?"),
                ("Comment t’aider sur cette partie de journée ?", "Pour {place} : où ton planning accroche ?"),
                ("Pose ta question ; je t’aide avec le contexte.", "{place} : de quoi as-tu besoin ?"),
            ],
            "Direct": [
                ("Bloc ouvert. Échange, timing, ça colle ?", "Bloc {place}. Échange, timing, ambiance ?"),
                ("Créneau vide. Quel ressenti ?", "{place}. Ajuster ou échanger ?"),
                ("Libre. Question ?", "{place}. Ça colle aujourd’hui ?"),
                ("Créneau. Vraie question ?", "{place}. Plan B, timing, certitude ?"),
                ("Ce morceau. Quoi ?", "{place}. Friction ?"),
                ("Go.", "{place}. Quoi ?"),
            ],
            "Energetic": [
                ('Créneau libre—précis : swap, timing, ou « ça fit » ? ⚡', "Bloc {place}—ce qui te gêne : swap, timing, vibe ✨"),
                ("Trou dans l’agenda—tu veux *quoi* ressentir aujourd’hui ? 🔥", "{place} dans ta journée—tu tunes ou tu swaps ? 💬"),
                ("Temps libre. Aucune question trop petite 🙌", "Pour {place}—vrai talk : tu doutes que ça colle ? 😅"),
                ("Reste humain : la vraie question ? ✨", "{place}… plan B, timing, certitude ? ⚡"),
                ("Je suis là—tu veux savoir quoi sur ce bout de journée ? 💬", "Je suis sur {place}—où ça coince ? 🔥"),
                ("Go—contexte par moi, vibe par toi 🙌", "{place}: dis ce qu’il te faut. Je match ✨"),
            ],
        },
    },
    "es": {
        "fallback": "este lugar",
        "explore": {
            "Friendly": [
                "Ooh—{place}. Estoy contigo. Gente, luz, mejor momento… ¿qué quieres saber?",
                "{place}… genial. ¿Dónde atascas—horario, ambiente o un plan B cerca?",
                "Vale, me centro en {place}. Sin rollo folleto—pregunta.",
                "Si estás probando {place}: ¿qué necesitas ahora—calma, energía, plan B?",
                "{place} está fijado. ¿Qué quieres saber antes de meterlo en tu día?",
                "Di la parte incómoda de {place}—¿niños, cita, «¿es una tontería?» Todo bien.",
            ],
            "Professional": [
                "Hablemos de {place}. ¿Qué necesitas: afluencia, luz o el mejor momento?",
                "Para {place}, ¿qué no te encaja—horario, ambiente o una alternativa cerca?",
                "Enfocados en {place}. Haz tu pregunta—respondo claro, sin marketing.",
                "Sobre {place}: ¿necesitas calma, energía o un plan B?",
                "{place} está listo. ¿Qué información necesitas antes de añadirlo al día?",
                "Pregunta sobre {place}—encaje, momento o dudas prácticas.",
            ],
            "Direct": [
                "{place}—gente, luz, mejor momento. ¿Qué?",
                "{place}. ¿Horario, vibe, plan B?",
                "{place}. ¿Tu pregunta?",
                "{place}. ¿Calma, energía o plan B?",
                "{place}. ¿Qué necesitas saber?",
                "{place}—di qué estás comprobando.",
            ],
            "Energetic": [
                "¡Ooh—{place}! Dime: gente, luz, mejor momento… ¿qué quieres saber? ✨",
                "{place}… me gusta. ¿Dónde atascas—tiempo, vibe, plan B? 🔥",
                "Fijados en {place}—sin folleto, pregunta 💬",
                "Test a {place}: ¿calma, energía o plan B cerca? ⚡",
                "{place} está anclado—¿qué quieres saber antes de meterlo en tu día? 🙌",
                "Di la parte incómoda de {place}—todo bien 😅",
            ],
        },
        "myday": {
            "Friendly": [
                ('Este hueco libre—¿qué quieres afinar: cambio, timing o “¿encaja o no”?', "El bloque de {place}—qué pica: cambio, timing, ambiente…"),
                ("Miro el hueco contigo. ¿Qué *quieres* sentir hoy?", "{place} en tu día—¿lo ajustas o lo cambias?"),
                ("Tiempo libre. Ninguna pregunta es pequeña.", "Sobre {place}—¿dudas de que encaje hoy?"),
                ("Sigamos siendo humanos: ¿cuál es la pregunta real?", "{place}… plan B, mejor momento o certeza?"),
                ("Aquí estoy. ¿Qué quieres saber de esta parte del día?", "Estoy en {place}. ¿Qué parte del plan roza?"),
                ("Dale—yo el contexto, tú el vibe.", "{place}: di qué necesitas. Yo encajo."),
            ],
            "Professional": [
                ("Este bloque libre: ¿cambio, timing o encaja en el plan?", "Tu bloque de {place}: ¿qué necesitas—cambio, timing o ambiente?"),
                ("Hueco vacío: ¿qué quieres lograr hoy?", "{place} en la agenda: ¿ajustar o sustituir?"),
                ("Tiempo libre. ¿Qué pregunta importa más?", "Sobre {place}: ¿encaja en el plan de hoy?"),
                ("Esta ventana: ¿cuál es la pregunta clave?", "{place}: ¿plan B, mejor momento o certeza?"),
                ("¿Cómo te ayudo con esta parte del día?", "Para {place}: ¿dónde se atasca tu plan?"),
                ("Haz tu pregunta; te ayudo con contexto.", "{place}: ¿qué necesitas?"),
            ],
            "Direct": [
                ("Bloque abierto. ¿Cambio, timing, encaja?", "Bloque {place}. ¿Cambio, timing, ambiente?"),
                ("Hueco vacío. ¿Qué sensación?", "{place}. ¿Ajustar o cambiar?"),
                ("Libre. ¿Pregunta?", "{place}. ¿Encaja hoy?"),
                ("Hueco. ¿Pregunta real?", "{place}. ¿Plan B, timing, certeza?"),
                ("Este trozo. ¿Qué?", "{place}. ¿Fricción?"),
                ("Dale.", "{place}. ¿Qué?"),
            ],
            "Energetic": [
                ('Hueco libre—fino: cambio, timing o «¿encaja»? ⚡', "Bloque {place}—qué molesta: cambio, timing, vibe ✨"),
                ("Hueco—¿qué *quieres* sentir hoy? 🔥", "{place} en tu día—¿tuneas o cambias? 💬"),
                ("Tiempo libre. Ninguna pregunta es pequeña 🙌", "Sobre {place}—¿dudas de que encaje hoy? 😅"),
                ("Sigue siendo humano: ¿la pregunta real? ✨", "{place}… ¿plan B, timing, certeza? ⚡"),
                ("Aquí estoy—¿qué quieres saber de este trozo del día? 💬", "Estoy en {place}—¿dónde roza el plan? 🔥"),
                ("Dale—contexto yo, vibe tú 🙌", "{place}: di qué necesitas. Yo matcheo ✨"),
            ],
        },
    },
}

PLACEHOLDER_META = {
    "placeholders": {"place": {"type": "String"}},
}


def flatten_locale(code: str) -> dict:
    bundle = LOCALES[code]
    out: dict = {"moodyPlaceThreadFallbackPlace": bundle["fallback"]}
    for st in STYLES:
        for i in range(6):
            k = f"moodyPlaceThreadExploreV{i}{st}"
            out[k] = bundle["explore"][st][i]
            out[f"@{k}"] = PLACEHOLDER_META.copy()
    for st in STYLES:
        for i in range(6):
            ke = f"moodyPlaceThreadMyDayV{i}{st}Empty"
            kp = f"moodyPlaceThreadMyDayV{i}{st}Place"
            empty_s, place_s = bundle["myday"][st][i]
            out[ke] = empty_s
            out[kp] = place_s
            out[f"@{kp}"] = PLACEHOLDER_META.copy()
    return out


NEEDLES = {
    "en": '"chatSheetMicTooltip": "Speak your question",\n',
    "nl": '"chatSheetMicTooltip": "Stel je vraag in (spraak)",\n',
    "de": '"chatSheetMicTooltip": "Frage per Spracheingabe",\n',
    "fr": '"chatSheetMicTooltip": "Dicter ta question",\n',
    "es": '"chatSheetMicTooltip": "Dictar tu pregunta",\n',
}


def format_insert(flat: dict) -> str:
    """ARB fragment lines after the mic tooltip line (comma continues JSON)."""
    # Stable order: fallback, explore V0..V5 × styles, myday ...
    keys = ["moodyPlaceThreadFallbackPlace"]
    for st in STYLES:
        for i in range(6):
            keys.append(f"moodyPlaceThreadExploreV{i}{st}")
            keys.append(f"@{f'moodyPlaceThreadExploreV{i}{st}'}")
    for st in STYLES:
        for i in range(6):
            keys.append(f"moodyPlaceThreadMyDayV{i}{st}Empty")
            kp = f"moodyPlaceThreadMyDayV{i}{st}Place"
            keys.append(kp)
            keys.append(f"@{kp}")

    lines = []
    for k in keys:
        v = flat[k]
        if k.startswith("@"):
            lines.append(f'  "{k}": {json.dumps(v, ensure_ascii=False)},')
        else:
            lines.append(f'  "{k}": {json.dumps(v, ensure_ascii=False)},')
    return "\n".join(lines) + "\n"


def merge_into_arb(arb_path: Path, locale: str) -> None:
    flat = flatten_locale(locale)
    insert = format_insert(flat)
    needle = NEEDLES[locale]
    text = arb_path.read_text(encoding="utf-8")
    if "moodyPlaceThreadFallbackPlace" in text:
        print(f"skip (already merged): {arb_path.name}")
        return
    if needle not in text:
        raise SystemExit(f"Needle not found in {arb_path}: {needle!r}")
    text = text.replace(needle, needle + insert, 1)
    arb_path.write_text(text, encoding="utf-8")
    print(f"merged {len(flat)} keys into {arb_path.name}")


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    for loc in ("en", "nl", "de", "fr", "es"):
        merge_into_arb(root / "lib" / "l10n" / f"app_{loc}.arb", loc)


if __name__ == "__main__":
    main()
