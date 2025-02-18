;; Licensing Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var license-nonce uint u0)

;; Data Maps
(define-map licenses
  { license-id: uint }
  {
    ip-id: uint,
    licensor: principal,
    licensee: principal,
    terms: (string-utf8 1000),
    start-date: uint,
    end-date: uint,
    royalty-rate: uint,
    active: bool
  }
)

(define-map royalties
  { ip-id: uint }
  { balance: uint }
)

;; Public Functions

;; Create a new license
(define-public (create-license (ip-id uint) (licensee principal) (terms (string-utf8 1000)) (start-date uint) (end-date uint) (royalty-rate uint))
  (let
    (
      (license-id (var-get license-nonce))
      (ip (unwrap! (contract-call? .ip-registration get-ip ip-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner ip)) err-unauthorized)
    (map-set licenses
      { license-id: license-id }
      {
        ip-id: ip-id,
        licensor: tx-sender,
        licensee: licensee,
        terms: terms,
        start-date: start-date,
        end-date: end-date,
        royalty-rate: royalty-rate,
        active: true
      }
    )
    (var-set license-nonce (+ license-id u1))
    (ok license-id)
  )
)

;; Pay royalties
(define-public (pay-royalties (license-id uint) (amount uint))
  (let
    (
      (license (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
      (current-royalties (default-to { balance: u0 } (map-get? royalties { ip-id: (get ip-id license) })))
    )
    (asserts! (is-eq tx-sender (get licensee license)) err-unauthorized)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set royalties
      { ip-id: (get ip-id license) }
      { balance: (+ (get balance current-royalties) amount) }
    )
    (ok true)
  )
)

;; Withdraw royalties
(define-public (withdraw-royalties (ip-id uint))
  (let
    (
      (ip (unwrap! (contract-call? .ip-registration get-ip ip-id) err-not-found))
      (current-royalties (default-to { balance: u0 } (map-get? royalties { ip-id: ip-id })))
    )
    (asserts! (is-eq tx-sender (get owner ip)) err-unauthorized)
    (asserts! (> (get balance current-royalties) u0) err-unauthorized)
    (try! (as-contract (stx-transfer? (get balance current-royalties) tx-sender tx-sender)))
    (map-set royalties
      { ip-id: ip-id }
      { balance: u0 }
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get license details
(define-read-only (get-license (license-id uint))
  (ok (unwrap! (map-get? licenses { license-id: license-id }) err-not-found))
)

;; Get royalty balance
(define-read-only (get-royalty-balance (ip-id uint))
  (ok (get balance (default-to { balance: u0 } (map-get? royalties { ip-id: ip-id }))))
)

;; Initialize contract
(begin
  (var-set license-nonce u0)
)

