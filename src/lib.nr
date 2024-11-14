use std::embedded_curve_ops::{ EmbeddedCurveScalar, fixed_base_scalar_mul };
use std::hash::poseidon;

// Generate public key: X = x*G
pub fn derive_pubkey(private_key: Field) -> std::embedded_curve_ops::EmbeddedCurvePoint {
    // Decompose scalar using from_field
    let scalar = EmbeddedCurveScalar::from_field(private_key);
    fixed_base_scalar_mul(scalar)
}

// Encrypt message
pub fn encrypt(
        pubkey: std::embedded_curve_ops::EmbeddedCurvePoint, 
        r: Field,
        msg: [Field; 32]
    ) -> (std::embedded_curve_ops::EmbeddedCurvePoint, [Field; 32]) {

    // Create EmbeddedCurveScalar for ephemeral private key
    let ephemeral_scalar = EmbeddedCurveScalar::new(r, 0);

    // Ephemeral public key: gR
    let gR = std::embedded_curve_ops::fixed_base_scalar_mul(ephemeral_scalar);

    // Shared key: gAR
    let shared_scalar = EmbeddedCurveScalar::new(r, 0);
    let gAR = std::embedded_curve_ops::multi_scalar_mul([pubkey], [shared_scalar]);

    // Encrypt message with Poseidon hash
    let mut cipherText = [0; 32];
    for i in 0..msg.len() {
        let hashKey = poseidon::bn254::hash_2([gAR.x, i as Field]);
        cipherText[i] = msg[i] + hashKey;
    }

    (gR, cipherText)
}

// Decrypt message
pub fn decrypt(
        privkey: Field, 
        cipher: (std::embedded_curve_ops::EmbeddedCurvePoint, [Field; 32])
    ) -> [Field; 32] {
    let (gR, cipherText) = cipher;

    let scalar = EmbeddedCurveScalar::from_field(privkey);  // Convert private key to EmbeddedCurveScalar
    // Shared key: gAR
    let gAR = std::embedded_curve_ops::multi_scalar_mul([gR], [scalar]);  // Use gR and scalar

    // Decrypt message
    let mut clearText = [0; 32];
    for i in 0..cipherText.len() {
        let hashKey = poseidon::bn254::hash_2([gAR.x, i as Field]);
        clearText[i] = cipherText[i] - hashKey;
    }

    clearText
}

/// Example main function
pub fn main(pubkey: std::embedded_curve_ops::EmbeddedCurvePoint, r: Field, msg: [Field; 32]) -> pub (std::embedded_curve_ops::EmbeddedCurvePoint, [Field; 32]) {
    encrypt(pubkey, r, msg)
}

#[test]
fn test_main() {
    let a = 123456;  // Private key
    let r = 7891;  // Random scalar for encryption
    let mut msg = [0; 32];
    msg[0] = 42;
    msg[1] = 137;
    msg[2] = 118;

    let gA = derive_pubkey(a);
    let (gR, cipherText) = encrypt(gA, r, msg);
    let clearText = decrypt(a, (gR, cipherText));

    assert(msg == clearText, "Decryption failed!");
}