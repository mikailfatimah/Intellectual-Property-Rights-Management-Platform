;; Dispute Resolution Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var dispute-nonce uint u0)

;; Data Maps
(define-map disputes
  { dispute-id: uint }
  {
    ip-id: uint,
    claimant: principal,
    respondent: principal,
    claim: (string-utf8 1000),
    status: (string-ascii 20),
    resolution: (optional (string-utf8 1000))
  }
)

;; Public Functions

;; File a dispute
(define-public (file-dispute (ip-id uint) (respondent principal) (claim (string-utf8 1000)))
  (let
    (
      (dispute-id (var-get dispute-nonce))
    )
    (map-set disputes
      { dispute-id: dispute-id }
      {
        ip-id: ip-id,
        claimant: tx-sender,
        respondent: respondent,
        claim: claim,
        status: "pending",
        resolution: none
      }
    )
    (var-set dispute-nonce (+ dispute-id u1))
    (ok dispute-id)
  )
)

;; Resolve dispute
(define-public (resolve-dispute (dispute-id uint) (resolution (string-utf8 1000)))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "resolved",
        resolution: (some resolution)
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get dispute details
(define-read-only (get-dispute (dispute-id uint))
  (ok (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set dispute-nonce u0)
)

