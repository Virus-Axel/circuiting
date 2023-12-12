use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction,
    sysvar::{rent::Rent, Sysvar},
    program::invoke,
};
const MAX_BOARD_WIDTH: u8 = 64;
const MAX_BOARD_HEIGHT: u8 = 128;
const DATA_SIZE_PER_UNIT: u8 = 3; // Component type, input 1, component specific data,

fn spacecraft_account_size() -> usize {
    const HEALTH_SIZE: usize = 2;
    const SPEED_SIZE: usize = 1;
    const LOCATION_SIZE: usize = 32;
    (MAX_BOARD_HEIGHT as usize) * (MAX_BOARD_WIDTH as usize) * (DATA_SIZE_PER_UNIT as usize)
        + LOCATION_SIZE
        + SPEED_SIZE
        + HEALTH_SIZE
}

pub fn create_spacecraft_account<'a>(
    accounts: &'a [AccountInfo<'a>],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let payer_account = next_account_info(accounts_iter)?;
    let new_account = next_account_info(accounts_iter)?;
    let system_program = next_account_info(accounts_iter)?;

    let account_size = spacecraft_account_size();
    let rent = Rent::get()?.minimum_balance(account_size);
    let instruction = &system_instruction::create_account(payer_account.key, new_account.key, rent, account_size as u64, system_program.key);

    invoke(instruction, &[payer_account.clone(), new_account.clone()])?;

    Ok(())
}

pub fn upgrade_health<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn add_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn remove_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn travel<'a>(accounts: &'a [AccountInfo<'a>], instruction_data: &[u8]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}
