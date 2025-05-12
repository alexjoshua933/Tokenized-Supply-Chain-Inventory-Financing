;; Valuation Contract
;; Determines appropriate financing amounts for inventory

(define-data-var admin principal tx-sender)

;; Valuation data structure
(define-map valuations
  { inventory-id: (string-ascii 36) }
  {
    appraised-value: uint,
    loan-to-value-ratio: uint,
    max-financing: uint,
    currency: (string-ascii 10),
    appraiser: principal,
    timestamp: uint
  }
)

;; Authorized appraisers
(define-map authorized-appraisers
  { appraiser: principal }
  { active: bool }
)

;; Add an appraiser
(define-public (add-appraiser (appraiser principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-set authorized-appraisers { appraiser: appraiser } { active: true }))
  )
)

;; Remove an appraiser
(define-public (remove-appraiser (appraiser principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2))
    (ok (map-delete authorized-appraisers { appraiser: appraiser }))
  )
)

;; Create a valuation for inventory
(define-public (create-valuation
    (inventory-id (string-ascii 36))
    (appraised-value uint)
    (loan-to-value-ratio uint)
    (currency (string-ascii 10)))
  (let ((appraiser-status (map-get? authorized-appraisers { appraiser: tx-sender })))
    (begin
      (asserts! (is-some appraiser-status) (err u3))
      (asserts! (get active (unwrap! appraiser-status (err u4))) (err u5))
      ;; Ensure loan-to-value ratio is between 0-100%
      (asserts! (<= loan-to-value-ratio u100) (err u6))

      (let ((max-financing (/ (* appraised-value loan-to-value-ratio) u100)))
        (ok (map-set valuations
          { inventory-id: inventory-id }
          {
            appraised-value: appraised-value,
            loan-to-value-ratio: loan-to-value-ratio,
            max-financing: max-financing,
            currency: currency,
            appraiser: tx-sender,
            timestamp: block-height
          }
        ))
      )
    )
  )
)

;; Get valuation details
(define-read-only (get-valuation (inventory-id (string-ascii 36)))
  (map-get? valuations { inventory-id: inventory-id })
)

;; Check if inventory has been valued
(define-read-only (is-inventory-valued (inventory-id (string-ascii 36)))
  (is-some (map-get? valuations { inventory-id: inventory-id }))
)

;; Get maximum financing amount
(define-read-only (get-max-financing (inventory-id (string-ascii 36)))
  (match (map-get? valuations { inventory-id: inventory-id })
    valuation-data (ok (get max-financing valuation-data))
    (err u7)
  )
)

;; Update valuation (only by original appraiser or admin)
(define-public (update-valuation
    (inventory-id (string-ascii 36))
    (appraised-value uint)
    (loan-to-value-ratio uint))
  (match (map-get? valuations { inventory-id: inventory-id })
    valuation-data
      (begin
        (asserts! (or
          (is-eq (get appraiser valuation-data) tx-sender)
          (is-eq (var-get admin) tx-sender))
          (err u8))
        (asserts! (<= loan-to-value-ratio u100) (err u9))

        (let ((max-financing (/ (* appraised-value loan-to-value-ratio) u100)))
          (ok (map-set valuations
            { inventory-id: inventory-id }
            (merge valuation-data {
              appraised-value: appraised-value,
              loan-to-value-ratio: loan-to-value-ratio,
              max-financing: max-financing,
              timestamp: block-height
            })
          ))
        )
      )
    (err u10)
  )
)
