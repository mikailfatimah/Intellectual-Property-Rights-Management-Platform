;; Collaboration Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var collaboration-nonce uint u0)

;; Data Maps
(define-map collaborations
  { collaboration-id: uint }c
  {
    ip-id: uint,
    collaborators: (list 10 principal),
    shares: (list 10 uint),
    revenue: uint
  }
)

;; Public Functions

;; Create a new collaboration
(define-public (create-collaboration (ip-id uint) (collaborators (list 10 principal)) (shares (list 10 uint)))
  (let
    (
      (collaboration-id (var-get collaboration-nonce))
      (ip (unwrap! (contract-call? .ip-registration get-ip ip-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get owner ip)) err-unauthorized)
    (asserts! (is-eq (len collaborators) (len shares)) err-unauthorized)
    (map-set collaborations
      { collaboration-id: collaboration-id }
      {
        ip-id: ip-id,
        collaborators: collaborators,
        shares: shares,
        revenue: u0
      }
    )
    (var-set collaboration-nonce (+ collaboration-id u1))
    (ok collaboration-id)
  )
)

;; Add revenue to collaboration
(define-public (add-revenue (collaboration-id uint) (amount uint))
  (let
    (
      (collaboration (unwrap! (map-get? collaborations { collaboration-id: collaboration-id }) err-not-found))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set collaborations
      { collaboration-id: collaboration-id }
      (merge collaboration { revenue: (+ (get revenue collaboration) amount) })
    )
    (ok true)
  )
)

;; Withdraw share
(define-public (withdraw-share (collaboration-id uint))
  (let
    (
      (collaboration (unwrap! (map-get? collaborations { collaboration-id: collaboration-id }) err-not-found))
      (index (unwrap! (index-of (get collaborators collaboration) tx-sender) err-unauthorized))
      (share (unwrap! (element-at (get shares collaboration) index) err-unauthorized))
      (total-shares (fold + (get shares collaboration) u0))
      (amount (/ (* (get revenue collaboration) share) total-shares))
    )
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    (map-set collaborations
      { collaboration-id: collaboration-id }
      (merge collaboration { revenue: (- (get revenue collaboration) amount) })
    )
    (ok amount)
  )
)

;; Read-only Functions

;; Get collaboration details
(define-read-only (get-collaboration (collaboration-id uint))
  (ok (unwrap! (map-get? collaborations { collaboration-id: collaboration-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set collaboration-nonce u0)
)

