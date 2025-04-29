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

;; Validates if a user is the original author of an item
(define-private (is-original-author? (item-identifier uint) (author principal))
  (match (map-get? collection-inventory { item-identifier: item-identifier })
    item-details (is-eq (get author item-details) author)
    false
  )
)

;; Retrieves the dimensional properties of an item
(define-private (retrieve-item-dimensions (item-identifier uint))
  (default-to u0 
    (get dimensions 
      (map-get? collection-inventory { item-identifier: item-identifier })
    )
  )
)

;; Validates that all categories meet system requirements
(define-private (validate-all-categories? (categories (list 10 (string-ascii 32))))
  (and
    (> (len categories) u0)
    (<= (len categories) u10)
    (is-eq (len (filter validate-category-descriptor? categories)) (len categories))
  )
)

;; Validates string fields for appropriate length constraints
(define-private (validate-text-field (text-value (string-ascii 64)) (minimum-length uint) (maximum-length uint))
  (and 
    (>= (len text-value) minimum-length)
    (<= (len text-value) maximum-length)
  )
)

;; Updates the collection counter and returns the previous value
(define-private (update-collection-counter)
  (let ((current-value (var-get collection-item-count)))
    (var-set collection-item-count (+ current-value u1))
    (ok current-value)
  )
)

;; Ensures category descriptor meets system requirements
(define-private (validate-category-descriptor? (category (string-ascii 32)))
  (and 
    (> (len category) u0)
    (< (len category) u33)
  )
)



;; =========================================
;; Core Public Operations
;; =========================================
;; Registers a new item into the collection database
(define-public (register-collection-item (name (string-ascii 64)) (dimensions uint) (context (string-ascii 128)) (categories (list 10 (string-ascii 32))))
  (let
    (
      (new-item-id (+ (var-get collection-item-count) u1))
    )
    ;; Input validation procedures
    (asserts! (and (> (len name) u0) (< (len name) u65)) ERROR-INVALID-ITEM-NAME)
    (asserts! (and (> dimensions u0) (< dimensions u1000000000)) ERROR-INVALID-ITEM-DIMENSIONS)
    (asserts! (and (> (len context) u0) (< (len context) u129)) ERROR-INVALID-ITEM-NAME)
    (asserts! (validate-all-categories? categories) ERROR-INVALID-ITEM-NAME)

    ;; Record the new collection item
    (map-insert collection-inventory
      { item-identifier: new-item-id }
      {
        name: name,
        author: tx-sender,
        dimensions: dimensions,
        timestamp: block-height,
        context: context,
        categories: categories
      }
    )

    ;; Configure default viewing permissions
    (map-insert viewing-permissions
      { item-identifier: new-item-id, viewer: tx-sender }
      { can-view: true }
    )

    ;; Update collection statistics
    (var-set collection-item-count new-item-id)
    (ok new-item-id)
  )
)

;; Retrieves the contextual information for a specific item
(define-public (retrieve-item-context (item-identifier uint))
  (let
    (
      (item-details (unwrap! (map-get? collection-inventory { item-identifier: item-identifier }) ERROR-ITEM-NONEXISTENT))
    )
    (ok (get context item-details))
  )
)

;; Checks if a specific user has viewing permissions for an item
(define-public (verify-viewer-access (item-identifier uint) (viewer principal))
  (let
    (
      (access-record (map-get? viewing-permissions { item-identifier: item-identifier, viewer: viewer }))
    )
    (ok (is-some access-record))
  )
)

;; Determines the number of categorization tags for an item
(define-public (count-item-categories (item-identifier uint))
  (let
    (
      (item-details (unwrap! (map-get? collection-inventory { item-identifier: item-identifier }) ERROR-ITEM-NONEXISTENT))
    )
    (ok (len (get categories item-details)))
  )
)

;; Validates if an item name meets system requirements
(define-public (verify-name-compliance (name (string-ascii 64)))
  (ok (and (> (len name) u0) (<= (len name) u64)))
)

;; Changes the authorship record of an item to a new creator
(define-public (reassign-item-ownership (item-identifier uint) (new-author principal))
  (let
    (
      (item-details (unwrap! (map-get? collection-inventory { item-identifier: item-identifier }) ERROR-ITEM-NONEXISTENT))
    )
    (asserts! (item-in-collection? item-identifier) ERROR-ITEM-NONEXISTENT)
    (asserts! (is-eq (get author item-details) tx-sender) ERROR-PERMISSION-DENIED)

    ;; Update ownership records
    (map-set collection-inventory
      { item-identifier: item-identifier }
      (merge item-details { author: new-author })
    )
    (ok true)
  )
)

;; Updates the metadata attributes of an existing item
(define-public (modify-item-details (item-identifier uint) (updated-name (string-ascii 64)) (updated-dimensions uint) (updated-context (string-ascii 128)) (updated-categories (list 10 (string-ascii 32))))
  (let
    (
      (item-details (unwrap! (map-get? collection-inventory { item-identifier: item-identifier }) ERROR-ITEM-NONEXISTENT))
    )
    ;; Validation procedures
    (asserts! (item-in-collection? item-identifier) ERROR-ITEM-NONEXISTENT)
    (asserts! (is-eq (get author item-details) tx-sender) ERROR-PERMISSION-DENIED)
    (asserts! (and (> (len updated-name) u0) (< (len updated-name) u65)) ERROR-INVALID-ITEM-NAME)
    (asserts! (and (> updated-dimensions u0) (< updated-dimensions u1000000000)) ERROR-INVALID-ITEM-DIMENSIONS)
    (asserts! (and (> (len updated-context) u0) (< (len updated-context) u129)) ERROR-INVALID-ITEM-NAME)
    (asserts! (validate-all-categories? updated-categories) ERROR-INVALID-ITEM-NAME)

    ;; Apply the updates to the item record
    (map-set collection-inventory
      { item-identifier: item-identifier }
      (merge item-details { 
        name: updated-name, 
        dimensions: updated-dimensions, 
        context: updated-context, 
        categories: updated-categories 
      })
    )
    (ok true)
  )
)

;; Removes an item completely from the collection database
(define-public (purge-collection-item (item-identifier uint))
  (let
    (
      (item-details (unwrap! (map-get? collection-inventory { item-identifier: item-identifier }) ERROR-ITEM-NONEXISTENT))
    )
    (asserts! (item-in-collection? item-identifier) ERROR-ITEM-NONEXISTENT)
    (asserts! (is-eq (get author item-details) tx-sender) ERROR-PERMISSION-DENIED)

    ;; Remove the item from the permanent collection
    (map-delete collection-inventory { item-identifier: item-identifier })
    (ok true)
  )
)


