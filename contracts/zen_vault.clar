;; ZenVault - Personal Journal with Mindfulness Prompts

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-entry (err u101)) 
(define-constant err-entry-not-found (err u102))
(define-constant err-not-shared (err u103))
(define-constant err-invalid-length (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-rate-limit (err u106))
(define-constant err-max-entries (err u107))

;; Configuration
(define-constant max-entries-per-user u1000)
(define-constant rate-limit-blocks u10)
(define-constant max-batch-size u10)

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

(define-map user-stats
    principal
    {
        total-entries: uint,
        last-entry-block: uint,
        shared-entries: uint
    }
)

;; Private Functions
(define-private (validate-rate-limit (user principal))
    (let (
        (stats (default-to {total-entries: u0, last-entry-block: u0, shared-entries: u0}
            (map-get? user-stats user)))
    )
    (if (< (- block-height (get last-entry-block stats)) rate-limit-blocks)
        err-rate-limit
        (ok true))
    )
)

(define-private (validate-entry-limit (user principal))
    (let (
        (stats (default-to {total-entries: u0, last-entry-block: u0, shared-entries: u0}
            (map-get? user-stats user)))
    )
    (if (>= (get total-entries stats) max-entries-per-user)
        err-max-entries
        (ok true))
    )
)

(define-private (update-user-stats (user principal) (is-shared bool))
    (let (
        (current-stats (default-to {total-entries: u0, last-entry-block: u0, shared-entries: u0}
            (map-get? user-stats user)))
        (new-shared (if is-shared (+ (get shared-entries current-stats) u1) (get shared-entries current-stats)))
    )
    (map-set user-stats
        user
        {
            total-entries: (+ (get total-entries current-stats) u1),
            last-entry-block: block-height,
            shared-entries: new-shared
        }
    )
    )
)

;; Public Functions
(define-public (add-entry (content (string-utf8 2048)) (prompt-id uint) (is-shared bool))
    (let
        (
            (entry-id (+ (var-get current-prompt-id) u1))
        )
        (asserts! (> (len content) u0) err-invalid-length)
        (try! (validate-prompt prompt-id))
        (try! (validate-rate-limit tx-sender))
        (try! (validate-entry-limit tx-sender))
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
        (update-user-stats tx-sender is-shared)
        (var-set current-prompt-id entry-id)
        (ok entry-id)
    )
)

[Previous functions remain unchanged...]
