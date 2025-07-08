HealthFlow
==========

Healthcare Data Sharing Consent Management Contract
---------------------------------------------------

This smart contract, `HealthFlow`, is a secure, blockchain-based system designed to manage patient consent for healthcare data sharing. It facilitates transparent and auditable interactions between patients, healthcare providers, researchers, and other authorized entities, ensuring patient autonomy, data privacy, and regulatory compliance within a decentralized environment.

Table of Contents
-----------------

-   HealthFlow

    -   Healthcare Data Sharing Consent Management Contract

    -   Table of Contents

    -   Features

    -   Contract Details

        -   Constants

        -   Data Maps and Variables

        -   Private Functions

        -   Public Functions

    -   Usage Examples

        -   1.  Register a Patient

        -   1.  Register a Healthcare Provider

        -   1.  Verify Patient/Provider (Contract Owner Only)

        -   1.  Grant Consent

        -   1.  Revoke Consent

        -   1.  Generate Healthcare Analytics Report

    -   Error Codes

    -   Deployment

    -   Contributing

    -   License

    -   Future Enhancements

Features
--------

-   **Patient Registration & Verification**: Allows patients to register and be verified by the contract owner.

-   **Healthcare Provider Registration & Verification**: Enables healthcare organizations to register and gain verification status.

-   **Granular Consent Management**: Patients can grant specific consent for data sharing, defining data categories, purpose, duration, and further sharing permissions.

-   **Consent Revocation**: Patients retain the right to revoke their consent at any time.

-   **Audit Trail**: Logs all data access and consent-related activities for transparency and compliance.

-   **Analytics & Reporting**: Provides healthcare providers with comprehensive analytics on data access patterns and consent statuses.

-   **Role-Based Access Control**: Ensures only authorized parties can perform specific actions (e.g., contract owner for verification).

Contract Details
----------------

### Constants

| Constant Name | Value | Description |
|---|---|---|
| `CONTRACT-OWNER` | `tx-sender` | The principal address that deployed the contract. |
| `ERR-NOT-AUTHORIZED` | `u1001` | Returned when the transaction sender is not authorized. |
| `ERR-PATIENT-NOT-FOUND` | `u1002` | Returned when a specified patient is not found. |
| `ERR-PROVIDER-NOT-FOUND` | `u1003` | Returned when a specified healthcare provider is not found. |
| `ERR-CONSENT-NOT-FOUND` | `u1004` | Returned when a specified consent record is not found or is already revoked. |
| `ERR-INVALID-DURATION` | `u1005` | Returned when the consent duration is outside acceptable limits. |
| `ERR-CONSENT-EXPIRED` | `u1006` | Returned when an attempt is made to access an expired consent. |
| `ERR-ALREADY-EXISTS` | `u1007` | Returned when attempting to register an entity that already exists. |
| `ERR-INVALID-PURPOSE` | `u1008` | Returned when the consent purpose is empty. |
| `ERR-PROVIDER-NOT-VERIFIED` | `u1009` | Returned when a healthcare provider is not verified. |
| `MIN-CONSENT-DURATION` | `u144` | Minimum consent duration in blocks (approx. 24 hours). |
| `MAX-CONSENT-DURATION` | `u52560` | Maximum consent duration in blocks (approx. 1 year). |

### Data Maps and Variables

-   **`patients`**: Stores patient information, including full name, registration date, verification status, and consent counts.

    -   Key: `{ patient-id: principal }`

    -   Value: `{ full-name: (string-ascii 100), date-registered: uint, is-verified: bool, total-consents: uint, active-consents: uint }`

-   **`healthcare-providers`**: Stores healthcare provider details, such as organization name, specialization, license number, verification status, and total data requests.

    -   Key: `{ provider-id: principal }`

    -   Value: `{ organization-name: (string-ascii 150), specialization: (string-ascii 100), license-number: (string-ascii 50), is-verified: bool, date-registered: uint, total-data-requests: uint }`

-   **`consent-records`**: Stores detailed consent information, including patient and provider IDs, data categories, purpose, consent status, expiry, and revocation details.

    -   Key: `{ consent-id: uint }`

    -   Value: `{ patient-id: principal, provider-id: principal, data-categories: (string-ascii 200), purpose: (string-ascii 200), consent-given: bool, date-granted: uint, expiry-block: uint, can-share-further: bool, revoked: bool, revocation-date: (optional uint) }`

-   **`access-logs`**: Records data access events for auditing purposes, including consent ID, accessing provider, timestamp, access type, and data categories accessed.

    -   Key: `{ log-id: uint }`

    -   Value: `{ consent-id: uint, accessing-provider: principal, access-timestamp: uint, access-type: (string-ascii 50), data-categories-accessed: (string-ascii 200) }`

-   **`next-consent-id`**: `(define-data-var uint u1)` - Counter for the next available consent ID.

-   **`next-log-id`**: `(define-data-var uint u1)` - Counter for the next available log ID.

-   **`total-patients`**: `(define-data-var uint u0)` - Total number of registered patients.

-   **`total-providers`**: `(define-data-var uint u0)` - Total number of registered healthcare providers.

### Private Functions

-   `(is-patient-verified (patient-id principal))`: Checks if a patient exists and is verified.

-   `(is-provider-verified (provider-id principal))`: Checks if a healthcare provider exists and is verified.

-   `(is-consent-valid (consent-id uint))`: Checks if a consent is currently valid (not expired and not revoked).

-   `(is-valid-duration (duration uint))`: Validates if a given duration is within the `MIN-CONSENT-DURATION` and `MAX-CONSENT-DURATION`.

-   `(update-patient-consent-count (patient-id principal) (increment bool))`: Increments or decrements the active consent count for a patient.

### Public Functions

-   `(register-patient (full-name (string-ascii 100)))`: Registers a new patient. Only the `tx-sender` can register themselves as a patient.

-   `(register-healthcare-provider (organization-name (string-ascii 150)) (specialization (string-ascii 100)) (license-number (string-ascii 50)))`: Registers a new healthcare provider. Only the `tx-sender` can register themselves as a provider.

-   `(verify-patient (patient-id principal))`: Verifies a registered patient. Callable only by the `CONTRACT-OWNER`.

-   `(verify-healthcare-provider (provider-id principal))`: Verifies a registered healthcare provider. Callable only by the `CONTRACT-OWNER`.

-   `(grant-consent (provider-id principal) (data-categories (string-ascii 200)) (purpose (string-ascii 200)) (duration-blocks uint) (can-share-further bool))`: Allows a verified patient (`tx-sender`) to grant consent to a verified healthcare provider for specific data categories and purposes, with a defined duration and further sharing permission.

-   `(revoke-consent (consent-id uint))`: Allows the patient who granted the consent (`tx-sender`) to revoke an active consent.

-   `(generate-healthcare-analytics-report (provider-id principal) (analysis-period-blocks uint) (include-expired-consents bool))`: Generates a comprehensive analytics report for a healthcare provider, detailing their data access patterns and consent statuses within a specified period. Callable by the `provider-id` or the `CONTRACT-OWNER`.

Usage Examples
--------------

### 1\. Register a Patient

```
(as-contract tx-sender (contract-call? 'SP123...my-contract register-patient "Alice Smith"))

```

### 2\. Register a Healthcare Provider

```
(as-contract tx-sender (contract-call? 'SP123...my-contract register-healthcare-provider "General Hospital" "General Medicine" "LIC12345"))

```

### 3\. Verify Patient/Provider (Contract Owner Only)

```
;; Verify a patient
(as-contract CONTRACT-OWNER (contract-call? 'SP123...my-contract verify-patient 'SP...patient-address))

;; Verify a healthcare provider
(as-contract CONTRACT-OWNER (contract-call? 'SP123...my-contract verify-healthcare-provider 'SP...provider-address))

```

### 4\. Grant Consent

```
(as-contract tx-sender (contract-call? 'SP123...my-contract grant-consent
  'SP...provider-address
  "Medical History, Lab Results"
  "For diagnosis and treatment"
  u1000 ;; duration in blocks
  true ;; can-share-further
))

```

### 5\. Revoke Consent

```
(as-contract tx-sender (contract-call? 'SP123...my-contract revoke-consent u1)) ;; Assuming consent-id u1

```

### 6\. Generate Healthcare Analytics Report

```
(as-contract tx-sender (contract-call? 'SP123...my-contract generate-healthcare-analytics-report
  'SP...provider-address
  u5000 ;; analysis-period-blocks
  true ;; include-expired-consents
))

```

Error Codes
-----------

-   `u1001`: Not Authorized - `tx-sender` does not have permission for the action.

-   `u1002`: Patient Not Found - The specified patient ID does not exist or is not verified.

-   `u1003`: Provider Not Found - The specified provider ID does not exist.

-   `u1004`: Consent Not Found - The specified consent ID does not exist or is already revoked.

-   `u1005`: Invalid Duration - The consent duration is outside the allowed range.

-   `u1006`: Consent Expired - The consent has already expired.

-   `u1007`: Already Exists - Attempt to register an entity that is already registered.

-   `u1008`: Invalid Purpose - The consent purpose string is empty.

-   `u1009`: Provider Not Verified - The healthcare provider is not verified.

Deployment
----------

This contract is written in Clarity and can be deployed on the Stacks blockchain. Ensure you have the Stacks CLI and a wallet configured for deployment.

Contributing
------------

Contributions are welcome! If you have suggestions for improvements or find any issues, please open an issue or submit a pull request on the GitHub repository.

License
-------

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE "null") file for details.

Future Enhancements
-------------------

-   **Advanced Access Control**: Implement more granular access control based on data categories and specific purposes.

-   **Consent Templates**: Allow the creation of predefined consent templates for common data sharing scenarios.

-   **Integration with Off-Chain Data Storage**: Explore secure methods for linking on-chain consent with off-chain encrypted healthcare data.

-   **User Interface (UI)**: Develop a user-friendly dApp interface for patients and providers to interact with the contract.

-   **Data Anonymization/Pseudonymization**: Integrate features for handling anonymized or pseudonymized data sharing.
