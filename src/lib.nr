use std::embedded_curve_ops::{ EmbeddedCurveScalar, fixed_base_scalar_mul };
use std::hash::poseidon;
use std::hash::poseidon2;

// Generate public key: X = x*G
pub fn derive_pubkey(private_key: Field) -> std::embedded_curve_ops::EmbeddedCurvePoint {
    // Decompose scalar using from_field
    let scalar = EmbeddedCurveScalar::from_field(private_key);

    // Debug print: scalar decomposition
    // std::println(f"private_key_scalar: {scalar}");

    // Perform scalar multiplication using the base point implicitly
    let public_key = fixed_base_scalar_mul(scalar);
    let r = public_key.x;
    let t = public_key.y;

    // std::println("Base Point: {base_point}");
    // std::println("Scalar: {scalar}");
    // std::println("Derived Public Key: {public_key}");

    // // Debug print: resulting public key
    // std::println(f"Derived Public Key: x={r}, y={t}, is_infinite={public_key.is_infinite}");

    public_key
}

// Encrypt message
pub fn encrypt(
        pubkey: std::embedded_curve_ops::EmbeddedCurvePoint, 
        r: Field,
        msg: [Field; 32]
    ) -> (std::embedded_curve_ops::EmbeddedCurvePoint, [Field; 32]) {
    
    std::println(f"test test ");
    // Create EmbeddedCurveScalar for ephemeral private key
    let ephemeral_scalar = EmbeddedCurveScalar::from_field(r);
    // let ephemeral_scalar = EmbeddedCurveScalar::new(r, 0);

    // Ephemeral public key: gR
    let gR = std::embedded_curve_ops::fixed_base_scalar_mul(ephemeral_scalar);

    // Shared key: gAR
    let gAR = std::embedded_curve_ops::multi_scalar_mul([pubkey], [ephemeral_scalar]);

    // Print shared secret bytes for verification
    let sharedXBytes: [u8; 32] = gAR.x.to_le_bytes();
    let sharedYBytes: [u8; 32] = gAR.y.to_le_bytes();

    // std::println(f"sharedXBytes: {sharedXBytes}");
    // std::println(f"sharedYBytes: {sharedYBytes}");

    
    // std::println(f"hashKey Inputs => {p_inputs}");

    // Encrypt message with Poseidon hash
    let mut cipherText = [0; 32];
    for i in 0..msg.len() {
        // let p_inputs = [gAR.x, i as Field];
        let p_inputs = [gAR.x];
        // std::println(f"hashKey Inputs => {p_inputs}");
        let hashKey = poseidon2::Poseidon2::hash(p_inputs, 1);
        // std::println(f"poseidon2 hash=> {hashKey}");
        cipherText[i] = msg[i] + hashKey;
    }

    // let first_msg = msg[0];
    // let first_ciphertext = cipherText[0];
    // std::println(f"first_ciphertext=> {first_ciphertext}");
    // std::println(f"first_msg=> {first_msg}");
    std::println(f"cipherText: {cipherText}");

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