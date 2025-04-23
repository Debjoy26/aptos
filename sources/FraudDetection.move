module 0x8c176b636fde8dcdff17583c30ce4086e7629c67be742b1009b8d98ff54e7f2d::FraudDetection {
    use aptos_framework::account;
    use aptos_framework::signer;
    use std::vector;

    /// Error codes
    const E_ALREADY_REPORTED: u64 = 1;
    const E_CASE_CLOSED: u64 = 2;

    /// Structure to store fraud case information
    struct FraudCase has key {
        reporter: address,
        category: vector<u8>, // "Insurance" or "Healthcare"
        description: vector<u8>,
        upvotes: u64,
        reviewers: vector<address>,
        is_active: bool
    }

    /// Create a new fraud case report
    public entry fun report_case(
        reporter: &signer,
        category: vector<u8>,
        description: vector<u8>
    ) {
        let reporter_addr = signer::address_of(reporter);

        let case = FraudCase {
            reporter: reporter_addr,
            category,
            description,
            upvotes: 0,
            reviewers: vector::empty<address>(),
            is_active: true
        };

        move_to(reporter, case);
    }

    /// Upvote a fraud case to mark as reviewed/verified
    public entry fun review_case(
        reviewer: &signer,
        case_reporter: address
    ) acquires FraudCase {
        let case = borrow_global_mut<FraudCase>(case_reporter);
        let reviewer_addr = signer::address_of(reviewer);

        // Check if the case is still open
        assert!(case.is_active, E_CASE_CLOSED);

        // Check if the reviewer has already reviewed
        let i = 0;
        let reviewers_len = vector::length(&case.reviewers);
        while (i < reviewers_len) {
            assert!(vector::borrow(&case.reviewers, i) != &reviewer_addr, E_ALREADY_REPORTED);
            i = i + 1;
        };

        // Add review (upvote)
        case.upvotes = case.upvotes + 1;
        vector::push_back(&mut case.reviewers, reviewer_addr);
    }

    /// Optionally close the case if enough reviews are collected
    public entry fun close_case(
        reporter: &signer
    ) acquires FraudCase {
        let case = borrow_global_mut<FraudCase>(signer::address_of(reporter));
        case.is_active = false;
    }
}
