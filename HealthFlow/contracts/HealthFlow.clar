;; Healthcare Data Sharing Consent Management Contract
;; A secure blockchain-based system for managing patient consent for healthcare data sharing
;; between healthcare providers, researchers, and other authorized entities.
;; Ensures patient autonomy, data privacy, and regulatory compliance.

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-PATIENT-NOT-FOUND (err u1002))
(define-constant ERR-PROVIDER-NOT-FOUND (err u1003))
(define-constant ERR-CONSENT-NOT-FOUND (err u1004))
(define-constant ERR-INVALID-DURATION (err u1005))
(define-constant ERR-CONSENT-EXPIRED (err u1006))
(define-constant ERR-ALREADY-EXISTS (err u1007))
(define-constant ERR-INVALID-PURPOSE (err u1008))
(define-constant ERR-PROVIDER-NOT-VERIFIED (err u1009))
(define-constant MIN-CONSENT-DURATION u144) ;; Minimum 24 hours (144 blocks)
(define-constant MAX-CONSENT-DURATION u52560) ;; Maximum 1 year (52560 blocks)

;; data maps and vars
;; Patient registry with basic information and verification status
(define-map patients 
    { patient-id: principal }
    {
        full-name: (string-ascii 100),
        date-registered: uint,
        is-verified: bool,
        total-consents: uint,
        active-consents: uint
    }
)

;; Healthcare provider registry with verification and specialization
(define-map healthcare-providers
    { provider-id: principal }
    {
        organization-name: (string-ascii 150),
        specialization: (string-ascii 100),
        license-number: (string-ascii 50),
        is-verified: bool,
        date-registered: uint,
        total-data-requests: uint
    }
)

;; Consent records storing detailed consent information
(define-map consent-records
    { consent-id: uint }
    {
        patient-id: principal,
        provider-id: principal,
        data-categories: (string-ascii 200),
        purpose: (string-ascii 200),
        consent-given: bool,
        date-granted: uint,
        expiry-block: uint,
        can-share-further: bool,
        revoked: bool,
        revocation-date: (optional uint)
    }
)

;; Data access logs for audit trail
(define-map access-logs
    { log-id: uint }
    {
        consent-id: uint,
        accessing-provider: principal,
        access-timestamp: uint,
        access-type: (string-ascii 50),
        data-categories-accessed: (string-ascii 200)
    }
)

;; Counter variables
(define-data-var next-consent-id uint u1)
(define-data-var next-log-id uint u1)
(define-data-var total-patients uint u0)
(define-data-var total-providers uint u0)

;; private functions
;; Verify if a patient exists and is verified
(define-private (is-patient-verified (patient-id principal))
    (match (map-get? patients { patient-id: patient-id })
        patient-data (get is-verified patient-data)
        false
    )
)

;; Verify if a healthcare provider exists and is verified
(define-private (is-provider-verified (provider-id principal))
    (match (map-get? healthcare-providers { provider-id: provider-id })
        provider-data (get is-verified provider-data)
        false
    )
)

;; Check if consent is currently valid (not expired and not revoked)
(define-private (is-consent-valid (consent-id uint))
    (match (map-get? consent-records { consent-id: consent-id })
        consent-data 
        (and 
            (get consent-given consent-data)
            (not (get revoked consent-data))
            (<= block-height (get expiry-block consent-data))
        )
        false
    )
)

;; Validate consent duration within acceptable limits
(define-private (is-valid-duration (duration uint))
    (and 
        (>= duration MIN-CONSENT-DURATION)
        (<= duration MAX-CONSENT-DURATION)
    )
)

;; Update patient consent counters
(define-private (update-patient-consent-count (patient-id principal) (increment bool))
    (match (map-get? patients { patient-id: patient-id })
        patient-data
        (map-set patients 
            { patient-id: patient-id }
            (merge patient-data {
                active-consents: (if increment 
                    (+ (get active-consents patient-data) u1)
                    (- (get active-consents patient-data) u1)
                )
            })
        )
        false
    )
)

;; public functions
;; Register a new patient in the system
(define-public (register-patient (full-name (string-ascii 100)))
    (let ((patient-id tx-sender))
        (asserts! (is-none (map-get? patients { patient-id: patient-id })) ERR-ALREADY-EXISTS)
        (map-set patients 
            { patient-id: patient-id }
            {
                full-name: full-name,
                date-registered: block-height,
                is-verified: false,
                total-consents: u0,
                active-consents: u0
            }
        )
        (var-set total-patients (+ (var-get total-patients) u1))
        (print { event: "patient-registered", patient-id: patient-id, name: full-name })
        (ok patient-id)
    )
)

;; Register a healthcare provider
(define-public (register-healthcare-provider 
    (organization-name (string-ascii 150))
    (specialization (string-ascii 100))
    (license-number (string-ascii 50))
)
    (let ((provider-id tx-sender))
        (asserts! (is-none (map-get? healthcare-providers { provider-id: provider-id })) ERR-ALREADY-EXISTS)
        (map-set healthcare-providers
            { provider-id: provider-id }
            {
                organization-name: organization-name,
                specialization: specialization,
                license-number: license-number,
                is-verified: false,
                date-registered: block-height,
                total-data-requests: u0
            }
        )
        (var-set total-providers (+ (var-get total-providers) u1))
        (print { event: "provider-registered", provider-id: provider-id, organization: organization-name })
        (ok provider-id)
    )
)

;; Verify a patient (contract owner only)
(define-public (verify-patient (patient-id principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (match (map-get? patients { patient-id: patient-id })
            patient-data
            (begin
                (map-set patients 
                    { patient-id: patient-id }
                    (merge patient-data { is-verified: true })
                )
                (print { event: "patient-verified", patient-id: patient-id })
                (ok true)
            )
            ERR-PATIENT-NOT-FOUND
        )
    )
)

;; Verify a healthcare provider (contract owner only)
(define-public (verify-healthcare-provider (provider-id principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (match (map-get? healthcare-providers { provider-id: provider-id })
            provider-data
            (begin
                (map-set healthcare-providers 
                    { provider-id: provider-id }
                    (merge provider-data { is-verified: true })
                )
                (print { event: "provider-verified", provider-id: provider-id })
                (ok true)
            )
            ERR-PROVIDER-NOT-FOUND
        )
    )
)

;; Grant consent for data sharing
(define-public (grant-consent 
    (provider-id principal)
    (data-categories (string-ascii 200))
    (purpose (string-ascii 200))
    (duration-blocks uint)
    (can-share-further bool)
)
    (let (
        (patient-id tx-sender)
        (consent-id (var-get next-consent-id))
        (expiry-block (+ block-height duration-blocks))
    )
        (asserts! (is-patient-verified patient-id) ERR-PATIENT-NOT-FOUND)
        (asserts! (is-provider-verified provider-id) ERR-PROVIDER-NOT-VERIFIED)
        (asserts! (is-valid-duration duration-blocks) ERR-INVALID-DURATION)
        (asserts! (> (len purpose) u0) ERR-INVALID-PURPOSE)
        
        (map-set consent-records
            { consent-id: consent-id }
            {
                patient-id: patient-id,
                provider-id: provider-id,
                data-categories: data-categories,
                purpose: purpose,
                consent-given: true,
                date-granted: block-height,
                expiry-block: expiry-block,
                can-share-further: can-share-further,
                revoked: false,
                revocation-date: none
            }
        )
        
        (update-patient-consent-count patient-id true)
        (var-set next-consent-id (+ consent-id u1))
        
        (print { 
            event: "consent-granted", 
            consent-id: consent-id,
            patient-id: patient-id,
            provider-id: provider-id,
            purpose: purpose,
            expiry-block: expiry-block
        })
        (ok consent-id)
    )
)

;; Revoke existing consent
(define-public (revoke-consent (consent-id uint))
    (match (map-get? consent-records { consent-id: consent-id })
        consent-data
        (begin
            (asserts! (is-eq tx-sender (get patient-id consent-data)) ERR-NOT-AUTHORIZED)
            (asserts! (not (get revoked consent-data)) ERR-CONSENT-NOT-FOUND)
            
            (map-set consent-records
                { consent-id: consent-id }
                (merge consent-data {
                    revoked: true,
                    revocation-date: (some block-height)
                })
            )
            
            (update-patient-consent-count (get patient-id consent-data) false)
            
            (print { 
                event: "consent-revoked", 
                consent-id: consent-id,
                patient-id: (get patient-id consent-data),
                revocation-date: block-height
            })
            (ok true)
        )
        ERR-CONSENT-NOT-FOUND
    )
)


