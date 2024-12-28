;; ZenVault - Personal Journal with Mindfulness Prompts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-entry (err u101))
(define-constant err-entry-not-found (err u102))

;; Data Variables
(define-data-var current-prompt-id uint u0)

;; Data Maps
(define-map journal-entries
    {entry-id: uint, owner: principal}
    {
        content: (string-utf8 2048),
        prompt-id: uint,
        timestamp: uint
    }
)

(define-map mindfulness-prompts
    uint
    {
        prompt: (string-ascii 256),
        active: bool
    }
)

;; Public Functions
(define-public (add-entry (content (string-utf8 2048)) (prompt-id uint))
    (let
        (
            (entry-id (+ (var-get current-prompt-id) u1))
        )
        (try! (validate-prompt prompt-id))
        (map-set journal-entries
            {entry-id: entry-id, owner: tx-sender}
            {
                content: content,
                prompt-id: prompt-id,
                timestamp: block-height
            }
        )
        (var-set current-prompt-id entry-id)
        (ok entry-id)
    )
)

(define-public (get-my-entry (entry-id uint))
    (let
        (
            (entry (map-get? journal-entries {entry-id: entry-id, owner: tx-sender}))
        )
        (if (is-some entry)
            (ok (unwrap-panic entry))
            err-entry-not-found
        )
    )
)

(define-public (add-prompt (prompt (string-ascii 256)))
    (if (is-eq tx-sender contract-owner)
        (let
            (
                (prompt-id (+ (var-get current-prompt-id) u1))
            )
            (map-set mindfulness-prompts
                prompt-id
                {
                    prompt: prompt,
                    active: true
                }
            )
            (var-set current-prompt-id prompt-id)
            (ok prompt-id)
        )
        err-not-owner
    )
)

;; Read Only Functions
(define-read-only (get-prompt (prompt-id uint))
    (map-get? mindfulness-prompts prompt-id)
)

(define-read-only (get-current-prompt)
    (map-get? mindfulness-prompts (var-get current-prompt-id))
)

;; Private Functions
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