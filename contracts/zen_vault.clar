;; ZenVault - Personal Journal with Mindfulness Prompts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-entry (err u101)) 
(define-constant err-entry-not-found (err u102))
(define-constant err-not-shared (err u103))
(define-constant err-invalid-length (err u104))
(define-constant err-unauthorized (err u105))

;; Data Variables
(define-data-var current-prompt-id uint u0)

;; Data Maps
(define-map journal-entries
    {entry-id: uint, owner: principal}
    {
        content: (string-utf8 2048),
        prompt-id: uint,
        timestamp: uint,
        last-modified: uint,
        is-shared: bool,
        reflection: (optional (string-utf8 1024)),
        is-deleted: bool
    }
)

(define-map mindfulness-prompts
    uint
    {
        prompt: (string-ascii 256),
        active: bool,
        category: (string-ascii 64)
    }
)

(define-map shared-entries
    {entry-id: uint}
    {owner: principal}
)

;; Public Functions
(define-public (add-entry (content (string-utf8 2048)) (prompt-id uint) (is-shared bool))
    (let
        (
            (entry-id (+ (var-get current-prompt-id) u1))
        )
        (asserts! (> (len content) u0) err-invalid-length)
        (try! (validate-prompt prompt-id))
        (map-set journal-entries
            {entry-id: entry-id, owner: tx-sender}
            {
                content: content,
                prompt-id: prompt-id,
                timestamp: block-height,
                last-modified: block-height,
                is-shared: is-shared,
                reflection: none,
                is-deleted: false
            }
        )
        (if is-shared
            (map-set shared-entries
                {entry-id: entry-id}
                {owner: tx-sender}
            )
            true
        )
        (var-set current-prompt-id entry-id)
        (ok entry-id)
    )
)

(define-public (delete-entry (entry-id uint))
    (let
        (
            (entry (map-get? journal-entries {entry-id: entry-id, owner: tx-sender}))
        )
        (asserts! (is-some entry) err-entry-not-found)
        (map-set journal-entries
            {entry-id: entry-id, owner: tx-sender}
            (merge (unwrap-panic entry)
                {is-deleted: true}
            )
        )
        (if (get is-shared (unwrap-panic entry))
            (map-delete shared-entries {entry-id: entry-id})
            true
        )
        (ok true)
    )
)

(define-public (get-my-entries (page uint) (limit uint))
    (let
        (
            (start (* page limit))
            (end (+ start limit))
        )
        (ok (filter get-active-entry 
            (map unwrap-panic
                (map-get? journal-entries 
                    {entry-id: entry-id, owner: tx-sender}
                )
                (range start end)
            )
        ))
    )
)

;; ... [Previous functions remain unchanged] ...

;; Read Only Functions
(define-read-only (get-prompt (prompt-id uint))
    (map-get? mindfulness-prompts prompt-id)
)

(define-read-only (get-current-prompt)
    (map-get? mindfulness-prompts (var-get current-prompt-id))
)

;; Private Functions
(define-private (get-active-entry (entry {content: (string-utf8 2048),
                                        prompt-id: uint,
                                        timestamp: uint,
                                        last-modified: uint,
                                        is-shared: bool,
                                        reflection: (optional (string-utf8 1024)),
                                        is-deleted: bool}))
    (not (get is-deleted entry))
)

(define-private (validate-prompt (prompt-id uint))
    (let
        (
            (prompt (map-get? mindfulness-prompts prompt-id))
        )
        (if (and
                (is-some prompt)
                (get active (unwrap-panic prompt))
            )
            (ok true)
            err-invalid-entry
        )
    )
)
