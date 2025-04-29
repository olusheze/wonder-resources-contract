;; Wonder Resources Database Contract

;; =========================================
;; Core System Constants and State Management Variables
;; =========================================
;; Platform administrator identification
(define-constant PLATFORM-ADMINISTRATOR tx-sender)

;; System Response Codes
(define-constant ERROR-INVALID-ITEM-DIMENSIONS (err u304))
(define-constant ERROR-PERMISSION-DENIED (err u305))
(define-constant ERROR-INVALID-BENEFICIARY (err u306))
(define-constant ERROR-ADMIN-RESTRICTED-OPERATION (err u307))
;; Viewing permissions management system
(define-map viewing-permissions
  { item-identifier: uint, viewer: principal }
  { can-view: bool }
)

(define-constant ERROR-NO-VIEWING-RIGHTS (err u308))
(define-constant ERROR-ITEM-NONEXISTENT (err u301))
(define-constant ERROR-ITEM-ALREADY-EXISTS (err u302))
(define-constant ERROR-INVALID-ITEM-NAME (err u303))

;; Counter tracking total items in collection
(define-data-var collection-item-count uint u0)

;; Primary collection inventory database
(define-map collection-inventory
  { item-identifier: uint }
  {
    name: (string-ascii 64),
    author: principal,
    dimensions: uint,
    timestamp: uint,
    context: (string-ascii 128),
    categories: (list 10 (string-ascii 32))
  }
)


;; =========================================
;; Utility Verification Functions
;; =========================================
;; Verifies if an item exists within the collection
(define-private (item-in-collection? (item-identifier uint))
  (is-some (map-get? collection-inventory { item-identifier: item-identifier }))
)
