;; Inventory Verification Contract
;; This contract validates the existence of goods in the supply chain

(define-data-var admin principal tx-sender)

;; Data structure for inventory items
(define-map inventory
  { inventory-id: (string-ascii 36) }
  {
    owner: principal,
    description: (string-ascii 100),
    quantity: uint,
    location: (string-ascii 50),
    verified: bool,
    timestamp: uint
  }
)

;; Verifiers authorized to validate inventory
(define-map authorized-verifiers
  { verifier: principal }
  { active: bool }
)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u1))
    (ok (map-set authorized-verifiers { verifier: verifier } { active: true }))
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2))
    (ok (map-delete authorized-verifiers { verifier: verifier }))
  )
)

;; Register new inventory
(define-public (register-inventory
    (inventory-id (string-ascii 36))
    (description (string-ascii 100))
    (quantity uint)
    (location (string-ascii 50)))
  (begin
    (asserts! (is-none (map-get? inventory { inventory-id: inventory-id })) (err u3))
    (ok (map-set inventory
      { inventory-id: inventory-id }
      {
        owner: tx-sender,
        description: description,
        quantity: quantity,
        location: location,
        verified: false,
        timestamp: block-height
      }
    ))
  )
)

;; Verify inventory exists
(define-public (verify-inventory (inventory-id (string-ascii 36)))
  (let ((verifier-status (map-get? authorized-verifiers { verifier: tx-sender })))
    (begin
      (asserts! (is-some verifier-status) (err u4))
      (asserts! (get active (unwrap! verifier-status (err u5))) (err u6))
      (match (map-get? inventory { inventory-id: inventory-id })
        inventory-data (ok (map-set inventory
                            { inventory-id: inventory-id }
                            (merge inventory-data { verified: true, timestamp: block-height })))
        (err u7)
      )
    )
  )
)

;; Check if inventory is verified
(define-read-only (is-inventory-verified (inventory-id (string-ascii 36)))
  (match (map-get? inventory { inventory-id: inventory-id })
    inventory-data (ok (get verified inventory-data))
    (err u8)
  )
)

;; Get inventory details
(define-read-only (get-inventory-details (inventory-id (string-ascii 36)))
  (map-get? inventory { inventory-id: inventory-id })
)

;; Transfer inventory ownership
(define-public (transfer-inventory (inventory-id (string-ascii 36)) (new-owner principal))
  (match (map-get? inventory { inventory-id: inventory-id })
    inventory-data
      (begin
        (asserts! (is-eq (get owner inventory-data) tx-sender) (err u9))
        (ok (map-set inventory
          { inventory-id: inventory-id }
          (merge inventory-data { owner: new-owner })
        )))
    (err u10)
  )
)
