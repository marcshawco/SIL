# Translation to-do

SIL 2.0 renamed the product's vocabulary. The English strings below were
rewritten; the five translations were carried across unchanged so nothing
breaks at runtime, but they still use the old game wording.

Writing product copy in five languages is a translator's job, not a guess,
so this file records exactly what needs redoing and nothing was invented.

## The vocabulary change

| Was | Is |
|---|---|
| Quest | Habit |
| Boss | Goal |
| Dungeon / Training | Focus |
| XP | Progress |
| Gold | Credits (CR) |
| HP | Momentum |
| Shop | Rewards |
| Death penalty | Recalibration |
| Penalty Zone | Catch-up |

Tone: plain, calm, second person. SIL states facts; it does not announce,
congratulate or scold. No exclamation marks, no bracketed `[SYSTEM]` voice.

## Strings needing a new translation (26)

### `%@ done. +%d progress (optional, so no credits).`

- **German** — currently: `%@ abgeschlossen. +%d XP (optionale Quest: kein Gold).`
- **Spanish** — currently: `%@ terminada. +%d XP (misión opcional: sin oro).`
- **French** — currently: `%@ terminée. +%d XP (quête facultative : pas d’or).`
- **Italian** — currently: `%@ completata. +%d XP (missione opzionale: niente oro).`
- **Russian** — currently: `%@ завершён. +%d XP (необязательный квест: без золота).`

### `%@ done. +%d progress, +%d CR.`

- **German** — currently: `%@ abgeschlossen. +%d XP, +%d Gold.`
- **Spanish** — currently: `%@ terminada. +%d XP, +%d oro.`
- **French** — currently: `%@ terminée. +%d XP, +%d or.`
- **Italian** — currently: `%@ completata. +%d XP, +%d oro.`
- **Russian** — currently: `%@ завершён. +%d XP, +%d золота.`

### `%@ done. +%d progress.`

- **German** — currently: `%@ bezwungen! +%d XP erhalten.`
- **Spanish** — currently: `¡%@ conquistado! +%d XP ganados.`
- **French** — currently: `%@ conquis ! +%d XP gagnés.`
- **Italian** — currently: `%@ conquistato! +%d XP ottenuti.`
- **Russian** — currently: `%@ покорено! Получено +%d XP.`

### `%@ is still open. A short go at it now keeps the run alive.`

- **German** — currently: `%@ wartet noch. Eine kurze Sitzung jetzt hält deine Serie und deinen XP-Fluss am Leben.`
- **Spanish** — currently: `%@ sigue esperando. Una sesión corta ahora mantiene viva tu racha y tu flujo de XP.`
- **French** — currently: `%@ attend toujours. Une courte session maintenant maintient votre série et vos gains d’XP.`
- **Italian** — currently: `%@ ti sta ancora aspettando. Una breve sessione ora mantiene viva la tua serie e il flusso XP.`
- **Russian** — currently: `%@ всё ещё ждёт. Короткая сессия сейчас сохранит вашу серию и поток XP.`

### `%@.`

- **German** — currently: `Du hast den Rang %@ erreicht!`
- **Spanish** — currently: `¡Has alcanzado el rango %@!`
- **French** — currently: `Vous avez atteint le rang %@ !`
- **Russian** — currently: `Вы достигли ранга %@!`

### `%d habit(s) still open today.`

- **German** — currently: `Du hast noch %d Quest(s) übrig. Schließe sie ab, um Strafen zu vermeiden.`
- **Spanish** — currently: `Te quedan %d misión(es). Complétalas para evitar penalizaciones.`
- **French** — currently: `Il vous reste %d quête(s). Terminez-les pour éviter les pénalités.`
- **Italian** — currently: `Hai ancora %d missione/i. Completale per evitare penalità.`
- **Russian** — currently: `У вас осталось %d квест(ов). Завершите их, чтобы избежать штрафов.`

### `%d habits done · +%d progress (optional habits earn no credits).`

- **German** — currently: `%d Quests abgeschlossen • +%d XP (optionale Quests geben nur XP).`
- **Spanish** — currently: `%d misiones completadas • +%d XP (las misiones opcionales solo otorgan XP).`
- **French** — currently: `%d quêtes terminées • +%d XP (les quêtes facultatives donnent seulement des XP).`
- **Italian** — currently: `%d missioni completate • +%d XP (le missioni opzionali danno solo XP).`
- **Russian** — currently: `Завершено квестов: %d • +%d XP (необязательные квесты дают только XP).`

### `%d habits done · +%d progress · +%d CR.`

- **German** — currently: `%d Quests abgeschlossen • +%d XP • +%d Gold.`
- **Spanish** — currently: `%d misiones completadas • +%d XP • +%d oro.`
- **French** — currently: `%d quêtes terminées • +%d XP • +%d or.`
- **Italian** — currently: `%d missioni completate • +%d XP • +%d oro.`
- **Russian** — currently: `Завершено квестов: %d • +%d XP • +%d золота.`

### `A goal is running out of time`

- **German** — currently: `⚠️ BOSS-FRIST NÄHERT SICH`
- **Spanish** — currently: `⚠️ SE ACERCA LA FECHA LÍMITE DEL JEFE`
- **French** — currently: `⚠️ DATE LIMITE DU BOSS APPROCHE`
- **Italian** — currently: `⚠️ SCADENZA BOSS IN ARRIVO`
- **Russian** — currently: `⚠️ СРОК ПО БОССУ ПРИБЛИЖАЕТСЯ`

### `A goal needs you`

- **German** — currently: `Boss-Druck steigt`
- **Spanish** — currently: `La presión del jefe aumenta`
- **French** — currently: `La pression du boss monte`
- **Italian** — currently: `Pressione del boss in aumento`
- **Russian** — currently: `Давление босса растёт`

### `Close today's habits before midnight to keep the run.`

- **German** — currently: `Schließe deine täglichen Quests vor Mitternacht ab, um deine Serie zu halten!`
- **Spanish** — currently: `¡Completa tus misiones diarias antes de medianoche para mantener tu racha!`
- **French** — currently: `Terminez vos quêtes quotidiennes avant minuit pour conserver votre série !`
- **Russian** — currently: `Завершите ежедневные квесты до полуночи, чтобы сохранить серию!`

### `Credits`

- **German** — currently: `Gold`

### `Focus done`

- **German** — currently: `🏰 DUNGEON GESCHAFFT`
- **French** — currently: `🏰 DONJON TERMINÉ`
- **Italian** — currently: `🏰 DUNGEON COMPLETATO`
- **Russian** — currently: `🏰 ПОДЗЕМЕЛЬЕ ПРОЙДЕНО`

### `Goal reached`

- **German** — currently: `💀 BOSS BESIEGT`
- **Spanish** — currently: `💀 JEFE DERROTADO`
- **French** — currently: `💀 BOSS VAINCU`
- **Italian** — currently: `💀 BOSS SCONFITTO`
- **Russian** — currently: `💀 БОСС ПОБЕЖДЁН`

### `Habit done`

- **German** — currently: `Quest abgeschlossen`
- **Spanish** — currently: `Misión completada`
- **French** — currently: `Quête terminée`
- **Italian** — currently: `Missione completata`
- **Russian** — currently: `Квест завершён`

### `Habit reminder`

- **German** — currently: `Quest-Erinnerung`
- **Spanish** — currently: `Recordatorio de misión`
- **French** — currently: `Rappel de quête`
- **Italian** — currently: `Promemoria missione`
- **Russian** — currently: `Напоминание о квесте`

### `Mark done`

- **German** — currently: `Quest abschließen`
- **Spanish** — currently: `Completar misión`
- **French** — currently: `Terminer la quête`
- **Italian** — currently: `Completa missione`
- **Russian** — currently: `Завершить квест`

### `Session finished. Your progress is banked.`

- **German** — currently: `Du hast den Dungeon bezwungen. Hol dir deine Belohnungen.`
- **French** — currently: `Vous avez conquis le donjon. Récupérez vos récompenses.`
- **Italian** — currently: `Hai conquistato il dungeon. Riscatta le tue ricompense.`
- **Russian** — currently: `Вы покорили подземелье. Заберите награды.`

### `Start focus`

- **German** — currently: `Dungeon betreten`
- **French** — currently: `Entrer dans le donjon`
- **Italian** — currently: `Entra nel dungeon`
- **Russian** — currently: `Войти в подземелье`

### `Still open`

- **German** — currently: `Quests unvollständig`
- **Spanish** — currently: `Misiones incompletas`
- **French** — currently: `Quêtes incomplètes`
- **Russian** — currently: `Квесты не завершены`

### `These attributes grow when you close this habit.`

- **German** — currently: `Ausgewählte Attribute erhalten XP, wenn diese Quest abgeschlossen wird.`

### `Today's habits`

- **German** — currently: `Quest-Zusammenfassung`
- **Spanish** — currently: `Resumen de misiones`
- **French** — currently: `Récapitulatif des quêtes`
- **Russian** — currently: `Сводка квестов`

### `Transmission Ending`

- **Spanish** — currently: `Fin de transmisión`
- **Italian** — currently: `Trasmissione in chiusura`

### `You're at %@. Tracking has started.`

- **German** — currently: `Du bist bei %@ angekommen. Quest-Tracking aktiv.`
- **Spanish** — currently: `Has llegado a %@. Seguimiento de misión activo.`
- **French** — currently: `Vous êtes arrivé à %@. Suivi de quête actif.`
- **Italian** — currently: `Sei arrivato a %@. Monitoraggio missione attivo.`
- **Russian** — currently: `Вы прибыли в %@. Отслеживание квеста активно.`

### `You've moved up`

- **German** — currently: `🎖️ RANGAUFSTIEG!`
- **Spanish** — currently: `🎖️ ¡SUBISTE DE RANGO!`
- **French** — currently: `🎖️ RANG SUPÉRIEUR !`
- **Russian** — currently: `🎖️ ПОВЫШЕНИЕ РАНГА!`

### `You've moved up. Level %d.`

- **German** — currently: `Du hast Level %d erreicht. Rang: %@`
- **Spanish** — currently: `Has alcanzado el nivel %d. Rango: %@`
- **French** — currently: `Vous avez atteint le niveau %d. Rang : %@`
- **Russian** — currently: `Вы достигли уровня %d. Ранг: %@`

