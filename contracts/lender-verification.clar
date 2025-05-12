;; Lender Verification Contract
;; Validates financial institutions participating in the system

(define-data-var admin principal tx-sender)

;; Lender data structure
(define-map lenders
  { lender-id: principal }
  {
    name: (string-ascii 50),
    credit-limit: uint,
    active: bool,
    verification-date: uint,
    risk-rating: uint  ;; 1-10 scale, lower is better
  }
)

;; Register a new lender (admin only)
(define-public (register-lender
    (lender-id principal)
    (name (string-ascii 50))
    (credit-limit uint)
    (risk-rating uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (asserts! (and (>= risk-rating u1) (<= risk-rating u10)) (err u2))
    (asserts! (is-none (map-get? lenders { lender-id: lender-id })) (err u3))

    (ok (map-set lenders
      { lender-id: lender-id }
      {
        name: name,
        credit-limit: credit-limit,
        active: true,
        verification-date: block-height,
        risk-rating: risk-rating
      }
    ))
  )
)

;; Update lender details (admin only)
(define-public (update-lender
    (lender-id principal)
    (credit-limit uint)
    (active bool)
    (risk-rating uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u4))
    (asserts! (and (>= risk-rating u1) (<= risk-rating u10)) (err u5))

    (match (map-get? lenders { lender-id: lender-id })
      lender-data
        (ok (map-set lenders
          { lender-id: lender-id }
          (merge lender-data {
            credit-limit: credit-limit,
            active: active,
            verification-date: block-height,
            risk-rating: risk-rating
          })
        ))
      (err u6)
    )
  )
)

;; Check if lender is verified and active
(define-read-only (is-lender-active (lender-id principal))
  (match (map-get? lenders { lender-id: lender-id })
    lender-data (get active lender-data)
    false
  )
)

;; Get lender details
(define-read-only (get-lender-details (lender-id principal))
  (map-get? lenders { lender-id: lender-id })
)

;; Get lender credit limit
(define-read-only (get-credit-limit (lender-id principal))
  (match (map-get? lenders { lender-id: lender-id })
    lender-data (ok (get credit-limit lender-data))
    (err u7)
  )
)

;; Get lender risk rating
(define-read-only (get-risk-rating (lender-id principal))
  (match (map-get? lenders { lender-id: lender-id })
    lender-data (ok (get risk-rating lender-data))
    (err u8)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u9))
    (ok (var-set admin new-admin))
  )
)
