use methods::spacecraft::activate_component;
use solana_program::{
    account_info::AccountInfo,
    entrypoint,
    entrypoint::ProgramResult,
    pubkey::Pubkey,
    program_error::ProgramError,
    msg,
};

pub mod methods;

use crate::methods::initialize_user::initialize_user;
use crate::methods::spacecraft::create_spacecraft_account;
use crate::methods::spacecraft::add_component;

pub const ID: &str = "2DzKRbWVuGgwiX4rAxQLbR5QzszGcmoKgSp7C1awzFsi";

// Declare and export the program's entrypoint
entrypoint!(process_instruction);

pub fn process_instruction<'a>(
    program_id: &Pubkey,
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {

    match instruction_data[0] {
        0 => create_spacecraft_account(accounts),
        1 => add_component(accounts, instruction_data),

        3 => activate_component(accounts, instruction_data),
        _ => Err(ProgramError::InvalidInstructionData),
    }
}