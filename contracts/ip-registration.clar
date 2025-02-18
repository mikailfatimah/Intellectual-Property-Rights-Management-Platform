;; IP Registration Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))

;; Data Variables
(define-data-var ip-nonce uint u0)

;; Data Maps
(define-map intellectual-properties
  { ip-id: uint }
  {
    owner: principal,
    title: (string-ascii 100),
    description: (string-utf8 500),
    creation-date: uint,
    registration-date: uint,
    ip-type: (string-ascii 20)
  }
)

;; Public Functions

;; Register new intellectual property
(define-public (register-ip (title (string-ascii 100)) (description (string-utf8 500)) (creation-date uint) (ip-type (string-ascii 20)))
  (let
    (
      (ip-id (var-get ip-nonce))
    )
    (asserts! (is-none (map-get? intellectual-properties { ip-id: ip-id })) err-already-registered)
    (map-set intellectual-properties
      { ip-id: ip-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        creation-date: creation-date,
        registration-date: block-height,
        ip-type: ip-type
      }
    )
    (var-set ip-nonce (+ ip-id u1))
    (ok ip-id)
  )
)

;; Transfer IP ownership
(define-public (transfer-ip (ip-id uint) (new-owner principal))
  (let
    (
      (ip (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner ip)) err-owner-only)
    (map-set intellectual-properties
      { ip-id: ip-id }
      (merge ip { owner: new-owner })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get IP details
(define-read-only (get-ip (ip-id uint))
  (ok (unwrap! (map-get? intellectual-properties { ip-id: ip-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set ip-nonce u0)
)

