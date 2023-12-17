use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction,
    sysvar::{rent::Rent, Sysvar, clock::Clock},
    program::{
        invoke_signed,
        invoke,
    },
};

use spl_token::instruction::{
    mint_to,
    burn,
};

const AUTHORITY_SEED: &[u8] = b"CIRCUITING_AUTHORITY_SEED";


pub fn create_ability_token<'a>(
    program_id: &Pubkey,
    accounts: &'a [AccountInfo<'a>],
) -> ProgramResult {
    Ok(())
}

pub fn give_token<'a>(
    program_id: &Pubkey,
    mint: &AccountInfo<'a>,
    token_account: &AccountInfo<'a>,
    token_program: &AccountInfo<'a>,
    mint_authority: &AccountInfo<'a>,
    rent: &AccountInfo<'a>,
    amount: u64,
) -> ProgramResult{

    let (_expected_mint_authority, bump) =
        Pubkey::find_program_address(&[AUTHORITY_SEED], &program_id);

    invoke_signed(
        &mint_to(
            &token_program.key,
            &mint.key,
            &token_account.key,
            &mint_authority.key,
            &[mint_authority.key],
            amount,
        )?,
        &[
            mint.clone(),
            mint_authority.clone(),
            token_account.clone(),
            token_program.clone(),
            rent.clone(),
        ],
        &[&[AUTHORITY_SEED, &[bump]]],
    )?;

    Ok(())
}

pub fn burn_token<'a>(
    program_id: &Pubkey,
    mint: &AccountInfo<'a>,
    token_account: &AccountInfo<'a>,
    token_program: &AccountInfo<'a>,
    mint_authority: &AccountInfo<'a>,
    amount: u64,
) -> ProgramResult{

    invoke(
        &burn(
            &token_program.key,
            &token_account.key,
            &mint.key,
            &mint_authority.key,
            &[mint_authority.key],
            amount,
        )?,
        &[
            token_account.clone(),
            mint.clone(),
            mint_authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}